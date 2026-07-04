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
    // Reset Generation (UPDATED FOR VIP NEGEDGE DETECTION)
    // =========================================================
    initial begin
        // 1. Start HIGH so the VIP is active at time 0
        rst_n   = 1;
        presetn = 1;
        
        // 2. Wait a few nanoseconds, then trigger the NEGEDGE
        #5; 
        rst_n   = 0;
        presetn = 0;
        
        // 3. Hold reset low for 50ns
        #50; 
        
        // 4. Release reset (Trigger the POSEDGE)
        rst_n   = 1;
        presetn = 1;
    end

    // =========================================================
    // Interface & BFM Instantiations
    // =========================================================
    camera_dvp_if          dvp_if      (.dvp_pclk(dvp_pclk), .rst_n(rst_n));
    
    // 1. Instantiate the raw APB pin interface (The REAL bus)
    apb_if                 apb_vip_if  (.pclk(pclk),         .preset_n(presetn)); 
    
    // 2. Instantiate the VIP's Master BFM Module
    apb_master_agent_bfm   apb_bfm_wrapper (.intf(apb_vip_if));
    
    // -------------------------------------------------------------
    // 3. VIP Slave BFM Instantiation (Modified to prevent multi-driver)
    // -------------------------------------------------------------
    // We create a dummy interface. The Slave Driver connects to this so 
    // it doesn't fight the DUT. The Monitor connects to the real bus.
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

        // Manually pass the split slave BFMs to the environment
        uvm_config_db#(virtual apb_slave_driver_bfm)::set(null,"*", "apb_slave_driver_bfm_0", apb_slave_drv_bfm_h); 
        uvm_config_db#(virtual apb_slave_monitor_bfm)::set(null,"*", "apb_slave_monitor_bfm_0", apb_slave_mon_bfm_h);

        run_test();
    end

endmodule
