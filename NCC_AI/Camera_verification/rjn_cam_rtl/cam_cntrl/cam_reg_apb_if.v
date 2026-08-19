// =================================================================================================
// Module: cam_reg_apb_if
//
// Description:
//   APB3 register file for the Camera Controller Module (CCM) - see CCM Registers (section
//   6.31.2) of the CCM spec. Zero-wait-state APB slave (PREADY is combinational: asserted
//   whenever PSEL && PENABLE) decoding word-aligned PADDR[6:2] into:
//
//     0x00  Format Register      [1:0] RW  - camera pixel format select
//     0x04  Resolution Register  [1:0] RW  - camera resolution select
//     0x08  Intr Line Tx  Cmt    [0]   RO  - live status
//     0x0C  Intr Line In  Cmt    [0]   RO  - live status
//     0x10  Intr Frm  Tx  Cmt    [0]   RO  - live status
//     0x14  Intr Buf Overrun    [0]   RO  - live status
//     0x18  Intr Buf Underrun   [0]   RO  - live status
//     0x1C  Interrupt Mask      [4:0] RW  - {buf_under, buf_over, frm_tx, line_in, line_tx}
//     0x20  Camera Control      [0]   RW  - camera interface enable
//     0x24  DMA Control         [0]   RW  - DMA trigger mask
//     0x28  Debug Control       [1:0] RW  - {sram buffer select, debug enable}
//
//   Interrupt status registers (0x08/0x0C/0x10/0x14/0x18) are read-only mirrors of the live,
//   already-clock-domain-crossed request level driven in on *_in (== *_hw_wr_en_in, both tied
//   to the same net by camera_controller). Their *_out port is NOT just an internal status bit:
//   camera_controller wires it straight to both the CCM's top-level interrupt pin AND the
//   ack_signal input of the matching intr_req_ack instance, so it must be a live, continuous
//   pass-through of *_in - the interrupt is a self-clearing, hardware-only req/ack loop (source
//   sets the request in camera_data_pipe -> syncs into *_in/*_out here -> syncs back as the ack
//   -> clears the source -> the pass-through drops a few cycles later). Gating *_out on an APB
//   read would deadlock: nothing would ever assert the interrupt pin the testbench/ISR waits on
//   in order to issue that very read. The APB read side is pure status observation with no side
//   effect, matching the spec note under "CCM Operation" that a read shortly after the interrupt
//   is set may still observe it pending, since the ack has to cross clock domains.
// =================================================================================================
//
`timescale 1 ns / 1 ps

module cam_reg_apb_if
(
  // Ports to functional block
  output [1:0]  frmt_cam_out,
  output [1:0]  res_cam_out,
  output        intr_line_trn_tx_cmt_out,
  input         intr_line_trn_tx_cmt_in,
  input         intr_line_trn_tx_cmt_hw_wr_en_in,
  output        intr_line_input_in_cmt_out,
  input         intr_line_input_in_cmt_in,
  input         intr_line_input_in_cmt_hw_wr_en_in,
  output        intr_frm_trn_tx_cmt_out,
  input         intr_frm_trn_tx_cmt_in,
  input         intr_frm_trn_tx_cmt_hw_wr_en_in,
  output        intr_buffer_over_buf_ovr_out,
  input         intr_buffer_over_buf_ovr_in,
  input         intr_buffer_over_buf_ovr_hw_wr_en_in,
  output        intr_buffer_under_buf_und_out,
  input         intr_buffer_under_buf_und_in,
  input         intr_buffer_under_buf_und_hw_wr_en_in,
  output        intr_mask_buf_under_out,
  output        intr_mask_buf_over_out,
  output        intr_mask_frm_tx_cmt_out,
  output        intr_mask_line_in_cmt_out,
  output        intr_mask_line_tx_cmt_out,
  output        cam_ctrl_en_out,
  output        dma_ctrl_trig_mask_out,
  output        debug_ctrl_sram_buffer_out,
  output        debug_ctrl_debug_en_out,

  // System bus ports
  output        PREADY,
  output [31:0] PRDATA,
  output        PSLVERR,
  input  [6:0]  PADDR,
  input  [2:0]  PPROT,
  input         PSEL,
  input         PENABLE,
  input         PWRITE,
  input  [31:0] PWDATA,
  input  [3:0]  PSTRB,
  input         PCLK,
  input         PRESETn
);

  // Unused per the spec (no protection-based access control defined for CCM registers)
  // (PPROT)

  // -----------------------------------------------------------------------------------
  // Address map (word-aligned offsets)
  // -----------------------------------------------------------------------------------
  localparam [6:0] ADDR_FORMAT       = 7'h00;
  localparam [6:0] ADDR_RESOLUTION   = 7'h04;
  localparam [6:0] ADDR_INTR_LINE_TX = 7'h08;
  localparam [6:0] ADDR_INTR_LINE_IN = 7'h0C;
  localparam [6:0] ADDR_INTR_FRM_TX  = 7'h10;
  localparam [6:0] ADDR_INTR_BUF_OVR = 7'h14;
  localparam [6:0] ADDR_INTR_BUF_UND = 7'h18;
  localparam [6:0] ADDR_INTR_MASK    = 7'h1C;
  localparam [6:0] ADDR_CAM_CTRL     = 7'h20;
  localparam [6:0] ADDR_DMA_CTRL     = 7'h24;
  localparam [6:0] ADDR_DEBUG_CTRL   = 7'h28;

  wire        apb_access = PSEL && PENABLE;      // access phase (zero wait states)
  wire        apb_wr     = apb_access && PWRITE;
  wire        apb_rd     = apb_access && !PWRITE;

  // -----------------------------------------------------------------------------------
  // RW storage registers
  // -----------------------------------------------------------------------------------
  reg [1:0] frmt_cam_r;       // Format Register        - 0x00, default RGB888 (2'b00)
  reg [1:0] res_cam_r;        // Resolution Register     - 0x04, default QVGA   (2'b11)
  reg [4:0] intr_mask_r;      // Interrupt Mask Register - 0x1C, default all unmasked (0)
  reg       cam_ctrl_en_r;    // Camera Control Register - 0x20, default disabled
  reg       dma_trig_mask_r;  // DMA Control Register    - 0x24, default unmasked
  reg [1:0] debug_ctrl_r;     // Debug Control Register  - 0x28, default disabled

  always @(posedge PCLK or negedge PRESETn)
    if (!PRESETn) begin
      frmt_cam_r      <= 2'b00;
      res_cam_r       <= 2'b11;
      intr_mask_r     <= 5'b0;
      cam_ctrl_en_r   <= 1'b0;
      dma_trig_mask_r <= 1'b0;
      debug_ctrl_r    <= 2'b0;
    end else if (apb_wr && PSTRB[0]) begin
      case (PADDR)
        ADDR_FORMAT:     frmt_cam_r      <= PWDATA[1:0];
        ADDR_RESOLUTION: res_cam_r       <= PWDATA[1:0];
        ADDR_INTR_MASK:  intr_mask_r     <= PWDATA[4:0];
        ADDR_CAM_CTRL:   cam_ctrl_en_r   <= PWDATA[0];
        ADDR_DMA_CTRL:   dma_trig_mask_r <= PWDATA[0];
        ADDR_DEBUG_CTRL: debug_ctrl_r    <= PWDATA[1:0];
        default: ;
      endcase
    end

  assign frmt_cam_out              = frmt_cam_r;
  assign res_cam_out                = res_cam_r;
  assign intr_mask_line_tx_cmt_out = intr_mask_r[0];
  assign intr_mask_line_in_cmt_out = intr_mask_r[1];
  assign intr_mask_frm_tx_cmt_out  = intr_mask_r[2];
  assign intr_mask_buf_over_out    = intr_mask_r[3];
  assign intr_mask_buf_under_out   = intr_mask_r[4];
  assign cam_ctrl_en_out           = cam_ctrl_en_r;
  assign dma_ctrl_trig_mask_out    = dma_trig_mask_r;
  assign debug_ctrl_debug_en_out   = debug_ctrl_r[0];
  assign debug_ctrl_sram_buffer_out = debug_ctrl_r[1];

  // -----------------------------------------------------------------------------------
  // Interrupt status registers - RO. *_out is a live, continuous pass-through of the
  // synchronized request level (*_in): this net IS the top-level interrupt pin AND the
  // ack fed back to camera_data_pipe (see module header) - it must self-clear in hardware,
  // not wait on an APB read.
  // -----------------------------------------------------------------------------------
  assign intr_line_trn_tx_cmt_out      = intr_line_trn_tx_cmt_in;
  assign intr_line_input_in_cmt_out    = intr_line_input_in_cmt_in;
  assign intr_frm_trn_tx_cmt_out       = intr_frm_trn_tx_cmt_in;
  assign intr_buffer_over_buf_ovr_out  = intr_buffer_over_buf_ovr_in;
  assign intr_buffer_under_buf_und_out = intr_buffer_under_buf_und_in;

  // Unused: *_hw_wr_en_in ports are wired to the same net as the matching *_in port by
  // camera_controller, so the live *_in level already carries everything *_out needs.
  // (intr_line_trn_tx_cmt_hw_wr_en_in, intr_line_input_in_cmt_hw_wr_en_in,
  //  intr_frm_trn_tx_cmt_hw_wr_en_in, intr_buffer_over_buf_ovr_hw_wr_en_in,
  //  intr_buffer_under_buf_und_hw_wr_en_in, apb_rd)

  // -----------------------------------------------------------------------------------
  // Read data mux
  // -----------------------------------------------------------------------------------
  reg [31:0] prdata_r;
  always @(*) begin
    case (PADDR)
      ADDR_FORMAT:       prdata_r = {30'b0, frmt_cam_r};
      ADDR_RESOLUTION:   prdata_r = {30'b0, res_cam_r};
      ADDR_INTR_LINE_TX: prdata_r = {31'b0, intr_line_trn_tx_cmt_in};
      ADDR_INTR_LINE_IN: prdata_r = {31'b0, intr_line_input_in_cmt_in};
      ADDR_INTR_FRM_TX:  prdata_r = {31'b0, intr_frm_trn_tx_cmt_in};
      ADDR_INTR_BUF_OVR: prdata_r = {31'b0, intr_buffer_over_buf_ovr_in};
      ADDR_INTR_BUF_UND: prdata_r = {31'b0, intr_buffer_under_buf_und_in};
      ADDR_INTR_MASK:    prdata_r = {27'b0, intr_mask_r};
      ADDR_CAM_CTRL:     prdata_r = {31'b0, cam_ctrl_en_r};
      ADDR_DMA_CTRL:     prdata_r = {31'b0, dma_trig_mask_r};
      ADDR_DEBUG_CTRL:   prdata_r = {30'b0, debug_ctrl_r};
      default:           prdata_r = 32'b0;
    endcase
  end

  assign PRDATA  = prdata_r;
  assign PREADY  = apb_access;   // zero wait-state slave
  assign PSLVERR = 1'b0;         // no error conditions defined for CCM registers

endmodule
