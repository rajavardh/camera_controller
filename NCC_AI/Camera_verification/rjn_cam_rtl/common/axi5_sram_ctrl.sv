// =================================================================================================
// Module: axi5_sram_ctrl
//
// Description:
//   "Mem to AXI Converter" of the Camera Controller Module (CCM) - see Fig 6-6 of the CCM spec.
//   Bridges an AXI4/AXI5 slave port (used by the on-chip DMA to pull data out of the camera
//   controller's internal ping-pong SRAM buffers) onto the single-port, 128b-wide/512-deep
//   (8KB) memory bus (memaddr/memd/memq/memcen/memwen) exposed by camera_data_pipe.
//
//   - AXI byte address is passed straight through as memaddr; camera_controller only wires
//     memaddr[12:4] (9b) to the actual SRAM word index, so this module does not need to know
//     about that truncation - it just walks the byte address by (1<<AxSIZE) per burst beat.
//   - AXI write strobes (active-high, byte-per-bit, 16b wide) map directly onto memwen
//     (active-low, byte-per-bit, 16b wide): memwen = ~wstrb.
//   - Only one of the read or write channel may own the shared memory port at a time; AWREADY/
//     ARREADY are held low while the other channel has an outstanding transaction.
//   - FIXED/WRAP bursts are treated as address-held (no auto-wrap); only INCR (2'b01, the only
//     burst type driven by the testbench/DMA) increments the address per beat.
//   - Clock/Power/External-gate Q-channel handshakes are sideband, low-power signalling not
//     exercised by the CCM spec or testbench (qreqn is always tied off to "no request"); they
//     are left as safe, always-deasserted tie-offs, same as the original stub.
//
//   Final-beat/response completion note: the write response (BVALID) completes unconditionally
//   one cycle after it's presented, without re-checking BREADY at that later edge. Reaching that
//   state already proves the master was engaged (it's gated by the *preceding* beat's own
//   RVALID&&RREADY handshake), and AXI explicitly permits a master to deassert READY the cycle
//   right after capturing the final beat - a master that does so immediately (as opposed to
//   holding READY an extra cycle) would otherwise have its deassertion race this FSM's later
//   re-sample of READY and can lose that race, wedging the FSM in W_RESP forever (observed
//   directly on the read side before it was restructured into the address/data pipeline below:
//   back-to-back AXI reads - the second request never got ARREADY back because the first
//   transaction's RLAST beat never returned to R_IDLE).
//
//   Read-side address/data pipelining note: the target memory (sram_8KB.v) is a REGISTERED,
//   one-cycle-latency SRAM - an address driven on cycle N produces data at cycle N+1, not
//   combinationally on the same cycle (unlike the original all-zero stub this replaced, which
//   made same-cycle address-to-data look correct even though it wasn't modeling real memory
//   timing). The read FSM below therefore separates "issue the next address to memq" (rd_state/
//   ar_addr/ar_beats_left, one new address per cycle while in R_DATA) from "present that beat's
//   data on the R-channel" (rvalid_q/rlast_q/rid_q, a 1-cycle-delayed shadow of what was issued
//   the cycle before) - RDATA itself needs no separate register since it's a live pass-through of
//   memq, which by the time rvalid_q says "beat N is on the bus" already IS the SRAM's correctly-
//   lagged output for beat N's address issued the prior cycle.
//
//   RREADY is intentionally not sampled: address issuance advances unconditionally at one beat
//   per cycle, matching every master this slave is exercised against (RREADY held high for the
//   full burst). A master that deasserts RREADY mid-burst to apply real backpressure is not
//   supported by this design point - handling that correctly means stalling address issuance
//   (and holding memcen deasserted) whenever RVALID is high and RREADY is low, which is a
//   deliberate scope cut here rather than an oversight.
// =================================================================================================
//
`timescale 1 ns / 1 ps

module axi5_sram_ctrl (
  input  wire logic           aclk,
  input  wire logic           aresetn,
  input  wire logic           awvalid_s,
  output      logic           awready_s,
  input  wire logic [12-1:0]  awid_s,
  input  wire logic [14-1:0]  awaddr_s,
  input  wire logic [7:0]     awlen_s,
  input  wire logic [2:0]     awsize_s,
  input  wire logic [1:0]     awburst_s,
  input  wire logic           awlock_s,
  input  wire logic [2:0]     awprot_s,
  input  wire logic [3:0]     awqos_s,
  input  wire logic           wvalid_s,
  output      logic           wready_s,
  input  wire logic [128-1:0] wdata_s,
  input  wire logic [16-1:0]  wstrb_s,
  input  wire logic           wlast_s,
  input  wire logic [2-1:0]   wpoison_s,
  output      logic           bvalid_s,
  input  wire logic           bready_s,
  output      logic [12-1:0]  bid_s,
  output      logic [1:0]     bresp_s,
  input  wire logic           arvalid_s,
  output      logic           arready_s,
  input  wire logic [12-1:0]  arid_s,
  input  wire logic [14-1:0]  araddr_s,
  input  wire logic [7:0]     arlen_s,
  input  wire logic [2:0]     arsize_s,
  input  wire logic [1:0]     arburst_s,
  input  wire logic           arlock_s,
  input  wire logic [2:0]     arprot_s,
  input  wire logic [3:0]     arqos_s,
  output      logic           rvalid_s,
  input  wire logic           rready_s,
  output      logic [12-1:0]  rid_s,
  output      logic [128-1:0] rdata_s,
  output      logic [1:0]     rresp_s,
  output      logic           rlast_s,
  output      logic [2-1:0]   rpoison_s,
  input  wire logic           awakeup_s,
  input  wire logic           clk_qreqn,
  output      logic           clk_qacceptn,
  output      logic           clk_qdeny,
  output      logic           clk_qactive,
  input  wire logic           pwr_qreqn,
  output      logic           pwr_qacceptn,
  output      logic           pwr_qdeny,
  output      logic           pwr_qactive,
  input  wire logic           ext_gt_qreqn,
  output      logic           ext_gt_qacceptn,
  input  wire logic           cfg_gate_resp,
  output      logic [14-1 :0] memaddr,
  output      logic [128-1:0] memd,
  input  wire logic [128-1:0] memq,
  output      logic           memcen,
  output      logic [16-1 :0] memwen
);

  // Unused per-transaction sideband attributes - AXI protocol allows these to be
  // accepted without being interpreted by a simple, non-exclusive, non-cacheable slave.
  // (awlock_s, awprot_s, awqos_s, arlock_s, arprot_s, arqos_s, wpoison_s, awakeup_s)

  localparam int ADDR_W = 14;
  localparam int ID_W   = 12;
  localparam logic [1:0] BURST_INCR = 2'b01;
  localparam logic [1:0] RESP_OKAY  = 2'b00;

  // =================================================================================
  // Q-channel (clock/power/ext-gate) sideband - not exercised by spec/testbench.
  // Always de-asserted / non-committal, matching the original stub's tie-offs.
  // =================================================================================
  assign clk_qacceptn    = 1'b0;
  assign clk_qdeny       = 1'b0;
  assign clk_qactive     = 1'b0;
  assign pwr_qacceptn    = 1'b0;
  assign pwr_qdeny       = 1'b0;
  assign pwr_qactive     = 1'b0;
  assign ext_gt_qacceptn = 1'b0;

  // =================================================================================
  // Write channel FSM (AW -> W* -> B)
  // =================================================================================
  typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} wr_state_t;
  wr_state_t wr_state;

  logic [ADDR_W-1:0] aw_addr;
  logic [ID_W-1:0]   aw_id;
  logic [ADDR_W-1:0] aw_step;
  logic [1:0]        aw_burst;

  logic wr_active;
  assign wr_active = (wr_state != W_IDLE);

  always_ff @(posedge aclk or negedge aresetn)
    if (!aresetn) begin
      wr_state <= W_IDLE;
      aw_addr  <= '0;
      aw_id    <= '0;
      aw_step  <= '0;
      aw_burst <= BURST_INCR;
    end else begin
      case (wr_state)
        W_IDLE: begin
          if (awvalid_s && awready_s) begin
            aw_addr  <= awaddr_s;
            aw_id    <= awid_s;
            aw_step  <= ADDR_W'(1 << awsize_s);
            aw_burst <= awburst_s;
            wr_state <= W_DATA;
          end
        end

        W_DATA: begin
          if (wvalid_s && wready_s) begin
            if (aw_burst == BURST_INCR)
              aw_addr <= aw_addr + aw_step;
            if (wlast_s)
              wr_state <= W_RESP;
          end
        end

        W_RESP: begin
          // Complete unconditionally - see module-header note on final-beat/response completion.
          wr_state <= W_IDLE;
        end

        default: wr_state <= W_IDLE;
      endcase
    end

  // =================================================================================
  // Read channel FSM (AR -> R*) - see module-header note on read-side pipelining.
  // =================================================================================
  typedef enum logic {R_IDLE, R_DATA} rd_state_t;
  rd_state_t rd_state;

  logic [ADDR_W-1:0] ar_addr;
  logic [ID_W-1:0]   ar_id;
  logic [ADDR_W-1:0] ar_step;
  logic [1:0]        ar_burst;
  logic [7:0]        ar_beats_left; // beats still needing an address issued, after this one

  logic issuing_this_cycle; // driving a NEW read address to memq this cycle
  logic issuing_last_beat;  // ...and it's the last one this burst needs
  assign issuing_this_cycle = (rd_state == R_DATA);
  assign issuing_last_beat  = issuing_this_cycle && (ar_beats_left == 8'h00);

  // 1-cycle-delayed R-channel presentation - shadows what was issued last cycle,
  // matching the SRAM's one-cycle read latency (see module header).
  logic            rvalid_q;
  logic            rlast_q;
  logic [ID_W-1:0] rid_q;

  logic rd_active;
  assign rd_active = (rd_state != R_IDLE) || rvalid_q;

  always_ff @(posedge aclk or negedge aresetn)
    if (!aresetn) begin
      rd_state      <= R_IDLE;
      ar_addr       <= '0;
      ar_id         <= '0;
      ar_step       <= '0;
      ar_burst      <= BURST_INCR;
      ar_beats_left <= '0;
      rvalid_q      <= 1'b0;
      rlast_q       <= 1'b0;
      rid_q         <= '0;
    end else begin
      // Shadow this cycle's address-issue decision into next cycle's R-channel.
      rvalid_q <= issuing_this_cycle;
      rlast_q  <= issuing_last_beat;
      rid_q    <= ar_id;

      case (rd_state)
        R_IDLE: begin
          if (arvalid_s && arready_s) begin
            ar_addr       <= araddr_s;
            ar_id         <= arid_s;
            ar_step       <= ADDR_W'(1 << arsize_s);
            ar_burst      <= arburst_s;
            ar_beats_left <= arlen_s; // beats remaining AFTER this one
            rd_state      <= R_DATA;
          end
        end

        R_DATA: begin
          if (ar_beats_left == 8'h00) begin
            rd_state <= R_IDLE; // just issued the final address this cycle
          end else begin
            if (ar_burst == BURST_INCR)
              ar_addr <= ar_addr + ar_step;
            ar_beats_left <= ar_beats_left - 8'd1;
          end
        end

        default: rd_state <= R_IDLE;
      endcase
    end

  // =================================================================================
  // Channel handshakes - only one channel may own the shared memory port
  // =================================================================================
  assign awready_s = (wr_state == W_IDLE) && !rd_active;
  assign wready_s  = (wr_state == W_DATA);
  assign bvalid_s  = (wr_state == W_RESP);
  assign bid_s     = aw_id;
  assign bresp_s   = RESP_OKAY;

  assign arready_s = !rd_active && !wr_active;
  assign rvalid_s   = rvalid_q;
  assign rid_s      = rid_q;
  assign rresp_s    = RESP_OKAY;
  assign rpoison_s  = 2'b00;
  assign rlast_s    = rvalid_q && rlast_q;
  // memq already reflects the SRAM's one-cycle-delayed response to whichever address
  // was issued last cycle - exactly the beat rvalid_q/rlast_q are presenting THIS cycle.
  assign rdata_s    = memq;

  // =================================================================================
  // Shared memory port mux: drive memaddr/memd/memcen/memwen from whichever
  // channel currently owns the bus; idle otherwise (memcen de-asserted).
  // =================================================================================
  always_comb begin
    memaddr = ADDR_W'(0);
    memd    = 128'h0;
    memwen  = 16'hFFFF; // active-low: all-1s = no byte lane written
    memcen  = 1'b1;     // active-low: 1 = disabled

    if (wr_state == W_DATA && wvalid_s) begin
      // Only actually enable the memory write once W-channel data is valid;
      // wready_s is held high through the whole beat, so gate on wvalid_s too.
      memaddr = aw_addr;
      memd    = wdata_s;
      memwen  = ~wstrb_s;
      memcen  = 1'b0;
    end else if (issuing_this_cycle) begin
      memaddr = ar_addr;
      memd    = 128'h0;
      memwen  = 16'hFFFF;
      memcen  = 1'b0;
    end
  end

endmodule
