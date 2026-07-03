
`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// =========================================================
// 1. UVM Package Imports (Must be in this exact order)
// =========================================================
import apb_global_pkg::*; // Corporate VIP Global
import apb_master_pkg::*; // Corporate VIP Master Agent
import dvp_pkg::*;        // Your Custom DVP IP
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
        rst_n   = 0;
        presetn = 0;
        #50; // Hold reset low for 50ns
        rst_n   = 1;
        presetn = 1;
    end

    // =========================================================
    // Interface & BFM Instantiations (THE FIX IS HERE)
    // =========================================================
    camera_dvp_if          dvp_if      (.dvp_pclk(dvp_pclk), .rst_n(rst_n));
    
    // 1. Instantiate the raw APB pin interface
    apb_if                 apb_vip_if  (.pclk(pclk),         .preset_n(presetn)); 
    
    // 2. Instantiate the VIP's BFM Module and pass it the interface!

    apb_master_agent_bfm   apb_bfm_wrapper (.intf(apb_vip_if));

    // Remaining interfaces
    //TODO FIX axi_s_cam_cntrl_if     axi_if      (.aclk(clk), .aresetn(rst_n)); 
    dma_trig_cam_cntrl_if  dma_if      (.clk(clk), .reset_n(rst_n));
    intr_cam_cntrl_if      intr_if     (.clk(clk), .reset_n(rst_n));

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

        //.i_axi_s_cam_cntrl_araddr   (axi_if.i_axi_s_cam_cntrl_araddr),
        //.i_axi_s_cam_cntrl_arburst  (axi_if.i_axi_s_cam_cntrl_arburst),
        //.i_axi_s_cam_cntrl_arid     (axi_if.i_axi_s_cam_cntrl_arid),
        //.i_axi_s_cam_cntrl_arlen    (axi_if.i_axi_s_cam_cntrl_arlen),
        //.o_axi_s_cam_cntrl_arready  (axi_if.o_axi_s_cam_cntrl_arready),
        //.i_axi_s_cam_cntrl_arsize   (axi_if.i_axi_s_cam_cntrl_arsize),
        //.i_axi_s_cam_cntrl_arvalid  (axi_if.i_axi_s_cam_cntrl_arvalid),
        //.i_axi_s_cam_cntrl_arlock   (axi_if.i_axi_s_cam_cntrl_arlock),
        //.i_axi_s_cam_cntrl_arprot   (axi_if.i_axi_s_cam_cntrl_arprot),
        //.i_axi_s_cam_cntrl_arqos    (axi_if.i_axi_s_cam_cntrl_arqos),

        //.i_axi_s_cam_cntrl_awaddr   (axi_if.i_axi_s_cam_cntrl_awaddr),
        //.i_axi_s_cam_cntrl_awakeup  (axi_if.i_axi_s_cam_cntrl_awakeup),
        //.i_axi_s_cam_cntrl_awburst  (axi_if.i_axi_s_cam_cntrl_awburst),
        //.i_axi_s_cam_cntrl_awid     (axi_if.i_axi_s_cam_cntrl_awid),
        //.i_axi_s_cam_cntrl_awlen    (axi_if.i_axi_s_cam_cntrl_awlen),
        //.o_axi_s_cam_cntrl_awready  (axi_if.o_axi_s_cam_cntrl_awready),
        //.i_axi_s_cam_cntrl_awsize   (axi_if.i_axi_s_cam_cntrl_awsize),
        //.i_axi_s_cam_cntrl_awvalid  (axi_if.i_axi_s_cam_cntrl_awvalid),
        //.i_axi_s_cam_cntrl_awlock   (axi_if.i_axi_s_cam_cntrl_awlock),
        //.i_axi_s_cam_cntrl_awprot   (axi_if.i_axi_s_cam_cntrl_awprot),
        //.i_axi_s_cam_cntrl_awqos    (axi_if.i_axi_s_cam_cntrl_awqos),

        //.i_axi_s_cam_cntrl_wdata    (axi_if.i_axi_s_cam_cntrl_wdata),
        //.i_axi_s_cam_cntrl_wlast    (axi_if.i_axi_s_cam_cntrl_wlast),
        //.o_axi_s_cam_cntrl_wready   (axi_if.o_axi_s_cam_cntrl_wready),
        //.i_axi_s_cam_cntrl_wstrb    (axi_if.i_axi_s_cam_cntrl_wstrb),
        //.i_axi_s_cam_cntrl_wvalid   (axi_if.i_axi_s_cam_cntrl_wvalid),
        //.i_axi_s_cam_cntrl_wpoison  (axi_if.i_axi_s_cam_cntrl_wpoison),

        //.o_axi_s_cam_cntrl_bid      (axi_if.o_axi_s_cam_cntrl_bid),
        //.i_axi_s_cam_cntrl_bready   (axi_if.i_axi_s_cam_cntrl_bready),
        //.o_axi_s_cam_cntrl_bresp    (axi_if.o_axi_s_cam_cntrl_bresp),
        //.o_axi_s_cam_cntrl_bvalid   (axi_if.o_axi_s_cam_cntrl_bvalid),

        //.o_axi_s_cam_cntrl_rdata    (axi_if.o_axi_s_cam_cntrl_rdata),
        //.o_axi_s_cam_cntrl_rid      (axi_if.o_axi_s_cam_cntrl_rid),
        //.o_axi_s_cam_cntrl_rlast    (axi_if.o_axi_s_cam_cntrl_rlast),
        //.i_axi_s_cam_cntrl_rready   (axi_if.i_axi_s_cam_cntrl_rready),
        //.o_axi_s_cam_cntrl_rresp    (axi_if.o_axi_s_cam_cntrl_rresp),
        //.o_axi_s_cam_cntrl_rvalid   (axi_if.o_axi_s_cam_cntrl_rvalid),
        //.o_axi_s_cam_cntrl_rpoison  (axi_if.o_axi_s_cam_cntrl_rpoison),

       // Wired directly to the VIP's native APB interface
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

        // DMA Trigger connections
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
        // Pass the custom interfaces we own
        uvm_config_db#(virtual camera_dvp_if)::set(null, "*", "dvp_vif", dvp_if);
        //TODO FIX uvm_config_db#(virtual axi_s_cam_cntrl_if)::set(null, "*", "vif_axi", axi_if);
        uvm_config_db#(virtual dma_trig_cam_cntrl_if)::set(null, "*", "vif_dma", dma_if);
        uvm_config_db#(virtual intr_cam_cntrl_if)::set(null, "*", "vif_intr", intr_if);

        // The apb_master_agent_bfm module is handling the APB config_db internally.

        run_test();
    end

endmodule
