`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// =========================================================
// 1. UVM Package Imports 
// =========================================================
import apb_global_pkg::*; // VIP Global
import apb_master_pkg::*; // VIP Master Agent
import axi4_globals_pkg::*; // AXI VIP Global
import axi4_master_pkg::*;  // AXI VIP Master
import dvp_pkg::*;        //  DVP IP
import camera_ss_pkg::*;  // The Subsystem Glue

module top;

    // =========================================================
    // Signal Declarations
    // =========================================================
    logic clk;           
    logic rst_n;         
    
    logic pclk;          
    logic presetn;       
    
    logic dvp_pclk;      
    wire  cam_clk_net;  

    // =========================================================
    // Clock Generation
    // =========================================================
    initial begin
        clk      = 0;
        pclk     = 0;
        dvp_pclk = 0;
    end
    
    always #5  clk      = ~clk;       // 100 MHz System Clock
    always #5  pclk     = ~pclk;      // 100 MHz APB Clock
    always #10 dvp_pclk = ~dvp_pclk;  // 50 MHz Camera Pixel Clock

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
    assign dvp_if.cam_clk = cam_clk_net; 
    
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

    // =========================================================
    // DUT Instantiation
    // =========================================================
    camera_controller dut (
        .rst_n                      (rst_n),
        .cam_clk                    (cam_clk_net), // Using the dedicated wire here

        .dvp_vsync                  (dvp_if.dvp_vsync),
        .dvp_href                   (dvp_if.dvp_href),
        .dvp_pclk                   (dvp_pclk),
        .dvp_data                   (dvp_if.dvp_data),

        // ---------------------------------------------------
        // APB Connections
        // ---------------------------------------------------
        .pclk                       (pclk),
        .presetn                    (presetn),
        .pprot                      (apb_vip_if.pprot),
        .psel                       (apb_vip_if.pselx), 
        .penable                    (apb_vip_if.penable),
        .pwrite                     (apb_vip_if.pwrite),
        .pstrb                      (apb_vip_if.pstrb),
        .paddr                      (apb_vip_if.paddr),
        .pwdata                     (apb_vip_if.pwdata),
        .prdata                     (apb_vip_if.prdata),
        .pslverr                    (apb_vip_if.pslverr),
        .pready                     (apb_vip_if.pready),

        // ---------------------------------------------------
        // AXI4 Connections (All 5 Channels)
        // ---------------------------------------------------
        // 1. Write Address Channel (AW)
        .i_axi_s_cam_cntrl_awid     (axi_vip_if.awid),
        .i_axi_s_cam_cntrl_awaddr   (axi_vip_if.awaddr),
        .i_axi_s_cam_cntrl_awlen    (axi_vip_if.awlen),
        .i_axi_s_cam_cntrl_awsize   (axi_vip_if.awsize),
        .i_axi_s_cam_cntrl_awburst  (axi_vip_if.awburst),
        .i_axi_s_cam_cntrl_awlock   (axi_vip_if.awlock),
        .i_axi_s_cam_cntrl_awprot   (axi_vip_if.awprot),
        .i_axi_s_cam_cntrl_awqos    (axi_vip_if.awqos),
        .i_axi_s_cam_cntrl_awvalid  (axi_vip_if.awvalid),
        .o_axi_s_cam_cntrl_awready  (axi_vip_if.awready),

        // 2. Write Data Channel (W)
        .i_axi_s_cam_cntrl_wdata    (axi_vip_if.wdata),
        .i_axi_s_cam_cntrl_wstrb    (axi_vip_if.wstrb),
        .i_axi_s_cam_cntrl_wlast    (axi_vip_if.wlast),
        .i_axi_s_cam_cntrl_wvalid   (axi_vip_if.wvalid),
        .o_axi_s_cam_cntrl_wready   (axi_vip_if.wready),

        // 3. Write Response Channel (B)
        .o_axi_s_cam_cntrl_bid      (axi_vip_if.bid),
        .o_axi_s_cam_cntrl_bresp    (axi_vip_if.bresp),
        .o_axi_s_cam_cntrl_bvalid   (axi_vip_if.bvalid),
        .i_axi_s_cam_cntrl_bready   (axi_vip_if.bready),

        // 4. Read Address Channel (AR)
        .i_axi_s_cam_cntrl_arid     (axi_vip_if.arid),
        .i_axi_s_cam_cntrl_araddr   (axi_vip_if.araddr),
        .i_axi_s_cam_cntrl_arlen    (axi_vip_if.arlen),
        .i_axi_s_cam_cntrl_arsize   (axi_vip_if.arsize),
        .i_axi_s_cam_cntrl_arburst  (axi_vip_if.arburst),
        .i_axi_s_cam_cntrl_arlock   (axi_vip_if.arlock),
        .i_axi_s_cam_cntrl_arprot   (axi_vip_if.arprot),
        .i_axi_s_cam_cntrl_arqos    (axi_vip_if.arqos),
        .i_axi_s_cam_cntrl_arvalid  (axi_vip_if.arvalid),
        .o_axi_s_cam_cntrl_arready  (axi_vip_if.arready),

        // 5. Read Data Channel (R)
        .o_axi_s_cam_cntrl_rid      (axi_vip_if.rid),
        .o_axi_s_cam_cntrl_rdata    (axi_vip_if.rdata),
        .o_axi_s_cam_cntrl_rresp    (axi_vip_if.rresp),
        .o_axi_s_cam_cntrl_rlast    (axi_vip_if.rlast),
        .o_axi_s_cam_cntrl_rvalid   (axi_vip_if.rvalid),
        .i_axi_s_cam_cntrl_rready   (axi_vip_if.rready),

        // ---------------------------------------------------
        // DMA Trigger connections
        // ---------------------------------------------------
        .dma_trig_req               (dma_if.dma_trig_req),
        .dma_trig_req_type          (dma_if.dma_trig_req_type),
        .dma_trig_ack               (dma_if.dma_trig_ack),
        .dma_trig_ack_type          (dma_if.dma_trig_ack_type),

        // ---------------------------------------------------
        // Interrupt connections
        // ---------------------------------------------------
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
        // Assuming your DUT expects these to be high/active to start
        dma_if.dma_trig_req      = 1; 
        dma_if.dma_trig_req_type = 1; // Set to whatever your active type is
        
        // Wait for DUT to acknowledge if it has a handshake
        wait (dma_if.dma_trig_ack == 1);
        `uvm_info("TOP", "DMA Trigger bypassed - RTL is now ready for AXI!", UVM_LOW)
    end    

    initial begin
        // Pass the custom interfaces we own
        uvm_config_db#(virtual camera_dvp_if)::set(null, "*", "dvp_vif", dvp_if);
        uvm_config_db#(virtual dma_trig_cam_cntrl_if)::set(null, "*", "vif_dma", dma_if);
        uvm_config_db#(virtual intr_cam_cntrl_if)::set(null, "*", "vif_intr", intr_if);

        // Pass the VIP Native Interfaces
        uvm_config_db#(virtual axi4_if)::set(null, "*", "axi4_if", axi_vip_if);

        // Manually pass the split slave BFMs to the environment
        uvm_config_db#(virtual apb_slave_driver_bfm)::set(null,"*", "apb_slave_driver_bfm_0", apb_slave_drv_bfm_h); 
        uvm_config_db#(virtual apb_slave_monitor_bfm)::set(null,"*", "apb_slave_monitor_bfm_0", apb_slave_mon_bfm_h);

        run_test();
    end

endmodule
