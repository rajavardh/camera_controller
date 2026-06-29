`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

module top;

    logic clk;           
    logic rst_n;         
    
    logic pclk;          
    logic presetn;       
    
    logic dvp_pclk;      


    camera_dvp_if          dvp_if  (.dvp_pclk(dvp_pclk), .rst_n(rst_n));
    axi_s_cam_cntrl_if     axi_if  (.clk(clk),           .reset(~rst_n)); 
    apb_cam_cntrl_if       apb_if  (.pclk(pclk),         .presetn(presetn));
    dma_trig_cam_cntrl_if  dma_if  (.clk(clk),           .reset_n(rst_n));
    intr_cam_cntrl_if      intr_if (.clk(clk),           .reset_n(rst_n));

    camera_controller dut (
        .rst_n                      (rst_n),
        .cam_clk                    (dvp_if.cam_clk), 

        .dvp_vsync                  (dvp_if.dvp_vsync),
        .dvp_href                   (dvp_if.dvp_href),
        .dvp_pclk                   (dvp_pclk),
        .dvp_data                   (dvp_if.dvp_data),

        .i_axi_s_cam_cntrl_araddr   (axi_if.i_axi_s_cam_cntrl_araddr),
        .i_axi_s_cam_cntrl_arburst  (axi_if.i_axi_s_cam_cntrl_arburst),
        .i_axi_s_cam_cntrl_arid     (axi_if.i_axi_s_cam_cntrl_arid),
        .i_axi_s_cam_cntrl_arlen    (axi_if.i_axi_s_cam_cntrl_arlen),
        .o_axi_s_cam_cntrl_arready  (axi_if.o_axi_s_cam_cntrl_arready),
        .i_axi_s_cam_cntrl_arsize   (axi_if.i_axi_s_cam_cntrl_arsize),
        .i_axi_s_cam_cntrl_arvalid  (axi_if.i_axi_s_cam_cntrl_arvalid),
        .i_axi_s_cam_cntrl_arlock   (axi_if.i_axi_s_cam_cntrl_arlock),
        .i_axi_s_cam_cntrl_arprot   (axi_if.i_axi_s_cam_cntrl_arprot),
        .i_axi_s_cam_cntrl_arqos    (axi_if.i_axi_s_cam_cntrl_arqos),

        .i_axi_s_cam_cntrl_awaddr   (axi_if.i_axi_s_cam_cntrl_awaddr),
        .i_axi_s_cam_cntrl_awakeup  (axi_if.i_axi_s_cam_cntrl_awakeup),
        .i_axi_s_cam_cntrl_awburst  (axi_if.i_axi_s_cam_cntrl_awburst),
        .i_axi_s_cam_cntrl_awid     (axi_if.i_axi_s_cam_cntrl_awid),
        .i_axi_s_cam_cntrl_awlen    (axi_if.i_axi_s_cam_cntrl_awlen),
        .o_axi_s_cam_cntrl_awready  (axi_if.o_axi_s_cam_cntrl_awready),
        .i_axi_s_cam_cntrl_awsize   (axi_if.i_axi_s_cam_cntrl_awsize),
        .i_axi_s_cam_cntrl_awvalid  (axi_if.i_axi_s_cam_cntrl_awvalid),
        .i_axi_s_cam_cntrl_awlock   (axi_if.i_axi_s_cam_cntrl_awlock),
        .i_axi_s_cam_cntrl_awprot   (axi_if.i_axi_s_cam_cntrl_awprot),
        .i_axi_s_cam_cntrl_awqos    (axi_if.i_axi_s_cam_cntrl_awqos),

        .i_axi_s_cam_cntrl_wdata    (axi_if.i_axi_s_cam_cntrl_wdata),
        .i_axi_s_cam_cntrl_wlast    (axi_if.i_axi_s_cam_cntrl_wlast),
        .o_axi_s_cam_cntrl_wready   (axi_if.o_axi_s_cam_cntrl_wready),
        .i_axi_s_cam_cntrl_wstrb    (axi_if.i_axi_s_cam_cntrl_wstrb),
        .i_axi_s_cam_cntrl_wvalid   (axi_if.i_axi_s_cam_cntrl_wvalid),
        .i_axi_s_cam_cntrl_wpoison  (axi_if.i_axi_s_cam_cntrl_wpoison),

        .o_axi_s_cam_cntrl_bid      (axi_if.o_axi_s_cam_cntrl_bid),
        .i_axi_s_cam_cntrl_bready   (axi_if.i_axi_s_cam_cntrl_bready),
        .o_axi_s_cam_cntrl_bresp    (axi_if.o_axi_s_cam_cntrl_bresp),
        .o_axi_s_cam_cntrl_bvalid   (axi_if.o_axi_s_cam_cntrl_bvalid),

        .o_axi_s_cam_cntrl_rdata    (axi_if.o_axi_s_cam_cntrl_rdata),
        .o_axi_s_cam_cntrl_rid      (axi_if.o_axi_s_cam_cntrl_rid),
        .o_axi_s_cam_cntrl_rlast    (axi_if.o_axi_s_cam_cntrl_rlast),
        .i_axi_s_cam_cntrl_rready   (axi_if.i_axi_s_cam_cntrl_rready),
        .o_axi_s_cam_cntrl_rresp    (axi_if.o_axi_s_cam_cntrl_rresp),
        .o_axi_s_cam_cntrl_rvalid   (axi_if.o_axi_s_cam_cntrl_rvalid),
        .i_axi_s_cam_cntrl_rpoison  (axi_if.i_axi_s_cam_cntrl_rpoison),

        .pclk                       (pclk),
        .presetn                    (presetn),
        .pprot                      (apb_if.pprot),
        .psel                       (apb_if.psel),
        .penable                    (apb_if.penable),
        .pwrite                     (apb_if.pwrite),
        .pstrb                      (apb_if.pstrb),
        .paddr                      (apb_if.paddr),
        .pwdata                     (apb_if.pwdata),
        .prdata                     (apb_if.prdata),
        .pslverr                    (apb_if.pslverr),
        .pready                     (apb_if.pready),

        .dma_trig_req               (dma_if.dma_trig_req),
        .dma_trig_req_type          (dma_if.dma_trig_req_type),
        .dma_trig_ack               (dma_if.dma_trig_ack),
        .dma_trig_ack_type          (dma_if.dma_trig_ack_type),

        .intr_line_tx_dn            (intr_if.intr_line_tx_dn),
        .intr_line_in_dn            (intr_if.intr_line_in_dn),
        .intr_frm_tx_dn             (intr_if.intr_frm_tx_dn),
        .intr_buf_over_err          (intr_if.intr_buf_over_err),
        .intr_buf_undr_err          (intr_if.intr_buf_undr_err)
    );

    initial begin
        uvm_config_db#(virtual camera_dvp_if)::set(null, "*", "vif_dvp", dvp_if);
        uvm_config_db#(virtual axi_s_cam_cntrl_if)::set(null, "*", "vif_axi", axi_if);
        uvm_config_db#(virtual apb_cam_cntrl_if)::set(null, "*", "vif_apb", apb_if);
        uvm_config_db#(virtual dma_trig_cam_cntrl_if)::set(null, "*", "vif_dma", dma_if);
        uvm_config_db#(virtual intr_cam_cntrl_if)::set(null, "*", "vif_intr", intr_if);

        run_test();
    end

endmodule

