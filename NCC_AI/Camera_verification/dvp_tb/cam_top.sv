`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// =========================================================
// 1. UVM Package Imports 
// =========================================================
import apb_global_pkg::*;   // VIP Global
import apb_master_pkg::*;   // VIP Master Agent
import axi4_globals_pkg::*; // AXI VIP Global
import axi4_master_pkg::*;  // AXI VIP Master
import dvp_pkg::*;          // DVP IP
import camera_ss_pkg::*;    // The Subsystem Glue

module top;

    // =========================================================
    // Signal Declarations
    // =========================================================
    logic clk;           
    logic rst_n;         
    
    logic pclk;          
    logic presetn;       
    
    logic dvp_pclk;      
    
    // =========================================================
    // Clock Generation
    // =========================================================
    initial begin
        clk         = 0;
        pclk        = 0;
        dvp_pclk    = 0;
    end
    
    always #5  clk         = ~clk;        // 100 MHz System Clock
    always #5  pclk        = ~pclk;       // 100 MHz APB Clock
    always #5 dvp_pclk    = ~dvp_pclk;   // 100 MHz Camera Pixel Clock
    
    //assign cam_clk_net = clk;
    // =========================================================
    // Reset Generation
    // =========================================================
    initial begin
        rst_n   = 1;
        presetn = 1;
        
        #5; 
        rst_n   = 0;
        presetn = 0;
        
        #50; 
        
        rst_n   = 1;
        presetn = 1;
    end

    // =========================================================
    // Interface & BFM Instantiations
    // =========================================================
  
    camera_dvp_if          dvp_if      (.dvp_pclk(dvp_pclk), .rst_n(rst_n));
    
    // --- APB Interfaces ---
    apb_if                 apb_vip_if  (.pclk(pclk),         .preset_n(presetn)); 
    apb_master_agent_bfm   apb_bfm_wrapper (.intf(apb_vip_if));
    
    apb_if dummy_apb_if (.pclk(pclk), .preset_n(presetn));

    apb_slave_driver_bfm apb_slave_drv_bfm_h(
        .pclk(dummy_apb_if.pclk),       .preset_n(dummy_apb_if.preset_n),
        .psel(dummy_apb_if.pselx),      .penable(dummy_apb_if.penable),
        .pprot(dummy_apb_if.pprot),     .paddr(dummy_apb_if.paddr),
        .pwrite(dummy_apb_if.pwrite),   .pwdata(dummy_apb_if.pwdata),
        .pstrb(dummy_apb_if.pstrb),     .pslverr(dummy_apb_if.pslverr),
        .pready(dummy_apb_if.pready),   .prdata(dummy_apb_if.prdata)
    );

    apb_slave_monitor_bfm apb_slave_mon_bfm_h (
        .pclk(apb_vip_if.pclk),         .preset_n(apb_vip_if.preset_n),
        .psel(apb_vip_if.pselx),        .paddr(apb_vip_if.paddr),
        .pwrite(apb_vip_if.pwrite),     .pwdata(apb_vip_if.pwdata),
        .pstrb(apb_vip_if.pstrb),       .pslverr(apb_vip_if.pslverr),
        .pready(apb_vip_if.pready),     .prdata(apb_vip_if.prdata),
        .penable(apb_vip_if.penable),   .pprot(apb_vip_if.pprot)
    );

    // --- AXI4 Interface ---
    axi4_if axi_vip_if (.aclk(clk), .aresetn(rst_n)); 
    axi4_master_agent_bfm axi_bfm_wrapper (.intf(axi_vip_if));

    // --- Sideband Interfaces ---
    dma_trig_cam_cntrl_if  dma_if      (.clk(clk), .reset_n(rst_n));
    intr_cam_cntrl_if      intr_if     (.clk(clk), .reset_n(rst_n));
 
    
    wire [11:0]  dut_rid;
    wire [11:0]  dut_bid;
    wire [127:0] dut_rdata;

    // 1. Pad the 4-bit IDs to 12-bit to satisfy the VIP
    assign axi_vip_if.rid = (dut_rid === 12'bx || dut_rid === 12'bz) ? 4'd0 : dut_rid[3:0];
    assign axi_vip_if.bid = (dut_bid === 12'bx || dut_bid === 12'bz) ? 4'd0 : dut_bid[3:0];

    // 2. Pad the 128-bit DUT data to the 512-bit VIP bus AND scrub X states
    wire [127:0] dut_rdata_clean;
    genvar i;
    generate
        for (i = 0; i < 128; i++) begin : scrub_rdata
            assign dut_rdata_clean[i] = (dut_rdata[i] === 1'bx || dut_rdata[i] === 1'bz) ? 1'b0 : dut_rdata[i];
        end
    endgenerate
    assign axi_vip_if.rdata = dut_rdata_clean;
    
    assign axi_vip_if.ruser = '0;
    assign axi_vip_if.buser = '0;

    // =========================================================
    // DUT Instantiation
    // =========================================================
    camera_controller dut (
        .rst_n                      (rst_n),
        .cam_clk                    (dvp_if.cam_clk), 

        .dvp_vsync                  (dvp_if.dvp_vsync),
        .dvp_href                   (dvp_if.dvp_href),
        .dvp_pclk                   (dvp_pclk),
        .dvp_data                   (dvp_if.dvp_data),

        // ARM AXI5 Power & Clock Management (MUST BE TIED HIGH)
        .i_axi_s_clk_qreqn          (1'b1), 
        .i_axi_s_pwr_qreqn          (1'b1), 
        .i_axi_s_ext_gt_qreqn       (1'b1), 
        .i_axi_s_cam_cntrl_awakeup  (1'b1), 
        .i_axi_s_cfg_gate_resp      (1'b1),
        
        .o_axi_s_ext_gt_qacceptn    (),
        .o_axi_s_pwr_qactive        (),
        .o_axi_s_pwr_qdeny          (),
        .o_axi_s_pwr_qacceptn       (),
        .o_axi_s_clk_qactive        (),
        .o_axi_s_clk_qdeny          (),
        .o_axi_s_clk_qacceptn       (),

        // SRAM Macro Configuration
        .SCR1_CAM_SRAM_EMA          (3'b000),
        .SCR1_CAM_SRAM_EMAW         (2'b00),
        .SCR1_CAM_SRAM_EMAS         (1'b0),
        
        // Debug signals
        .dbg_cam_buffer_b_empty     (),
        .dbg_cam_buffer_a_empty     (),
        .dbg_cam_buffer_b_full      (),
        .dbg_cam_buffer_a_full      (),
        .dbg_cam_buffer_a_select    (),

        // APB Connections
        .pclk                       (pclk),
        .presetn                    (presetn),
        .pprot                      (apb_vip_if.pprot),
        .psel                       (apb_vip_if.pselx === 1'b1 ? 1'b1 : 1'b0), 
        .penable                    (apb_vip_if.penable === 1'b1 ? 1'b1 : 1'b0),
        .pwrite                     (apb_vip_if.pwrite),
        .pstrb                      (apb_vip_if.pstrb),
        .paddr                      (apb_vip_if.paddr),
        .pwdata                     (apb_vip_if.pwdata),
        .prdata                     (apb_vip_if.prdata),
        .pslverr                    (apb_vip_if.pslverr),
        .pready                     (apb_vip_if.pready),

        // AXI4 Connections 
        
        // --- READ CHANNEL (Active) ---
        .i_axi_s_cam_cntrl_arvalid  (axi_vip_if.arvalid === 1'b1 ? 1'b1 : 1'b0),
        .o_axi_s_cam_cntrl_arready  (axi_vip_if.arready),
        .i_axi_s_cam_cntrl_araddr   (axi_vip_if.araddr[13:0]),
        
        // Pad VIP's 4-bit ID to DUT's 12-bit port
        .i_axi_s_cam_cntrl_arid     ({8'h00, axi_vip_if.arid[3:0]}), 
        
        .i_axi_s_cam_cntrl_arlen    (axi_vip_if.arlen),
        .i_axi_s_cam_cntrl_arsize   (axi_vip_if.arsize),
        .i_axi_s_cam_cntrl_arburst  (axi_vip_if.arburst),
        .i_axi_s_cam_cntrl_arprot   (3'b000),
        .i_axi_s_cam_cntrl_arqos    (axi_vip_if.arqos),
        .i_axi_s_cam_cntrl_arlock   (1'b0), 
        .i_axi_s_cam_cntrl_wpoison  (2'b00), 
        .o_axi_s_cam_cntrl_rpoison  (),
        
        .o_axi_s_cam_cntrl_rid      (dut_rid),
        .o_axi_s_cam_cntrl_rdata    (dut_rdata),
        
        .o_axi_s_cam_cntrl_rresp    (axi_vip_if.rresp),
        .o_axi_s_cam_cntrl_rlast    (axi_vip_if.rlast),
        .o_axi_s_cam_cntrl_rvalid   (axi_vip_if.rvalid),
        .i_axi_s_cam_cntrl_rready   (axi_vip_if.rready),

        // --- WRITE CHANNEL 
        .i_axi_s_cam_cntrl_awvalid  (1'b0), 
        .o_axi_s_cam_cntrl_awready  (axi_vip_if.awready),
        .i_axi_s_cam_cntrl_awaddr   (14'd0),
        .i_axi_s_cam_cntrl_awid     (12'd0),
        .i_axi_s_cam_cntrl_awlen    (8'd0),
        .i_axi_s_cam_cntrl_awsize   (3'd0),
        .i_axi_s_cam_cntrl_awburst  (2'd0),
        .i_axi_s_cam_cntrl_awprot   (3'd0),
        .i_axi_s_cam_cntrl_awqos    (4'd0),
        .i_axi_s_cam_cntrl_awlock   (1'b0),
        
        .i_axi_s_cam_cntrl_wvalid   (1'b0),
        .o_axi_s_cam_cntrl_wready   (axi_vip_if.wready),
        .i_axi_s_cam_cntrl_wdata    (128'd0),
        .i_axi_s_cam_cntrl_wstrb    (16'd0),
        .i_axi_s_cam_cntrl_wlast    (1'b0),
        
        .o_axi_s_cam_cntrl_bid      (dut_bid),
        
        .o_axi_s_cam_cntrl_bresp    (axi_vip_if.bresp),
        .o_axi_s_cam_cntrl_bvalid   (axi_vip_if.bvalid),
        .i_axi_s_cam_cntrl_bready   (1'b1),
        
        // RESTORED: DUT's internal DMA trigger logic connected to the dma_if
        .dma_trig_req               (dma_if.dma_trig_req), 
        .dma_trig_req_type          (dma_if.dma_trig_req_type), 
        .dma_trig_ack               (dma_if.dma_trig_ack),
        .dma_trig_ack_type          (dma_if.dma_trig_ack_type),

        // Interrupt connections
        .intr_line_tx_dn            (intr_if.intr_line_tx_dn),
        .intr_line_in_dn            (intr_if.intr_line_in_dn),
        .intr_frm_tx_dn             (intr_if.intr_frm_tx_dn),
        .intr_buf_over_err          (intr_if.intr_buf_over_err),
        .intr_buf_undr_err          (intr_if.intr_buf_undr_err)
    );

    // =========================================================
    // UVM Setup and Execution
    // =========================================================
    initial begin
        uvm_config_db#(virtual camera_dvp_if)::set(null, "*", "dvp_vif", dvp_if);
        uvm_config_db#(virtual dma_trig_cam_cntrl_if)::set(null, "*", "vif_dma", dma_if);
        uvm_config_db#(virtual intr_cam_cntrl_if)::set(null, "*", "vif_intr", intr_if);

        uvm_config_db#(virtual axi4_if)::set(null, "*", "axi4_if", axi_vip_if);

        uvm_config_db#(virtual apb_slave_driver_bfm)::set(null,"*", "apb_slave_driver_bfm_0", apb_slave_drv_bfm_h); 
        uvm_config_db#(virtual apb_slave_monitor_bfm)::set(null,"*", "apb_slave_monitor_bfm_0", apb_slave_mon_bfm_h);

        run_test();
    end


endmodule
