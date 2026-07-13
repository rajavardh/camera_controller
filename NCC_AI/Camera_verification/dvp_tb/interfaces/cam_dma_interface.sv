`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"

interface dma_trig_cam_cntrl_if (input logic clk, input logic reset_n);

  logic       dma_trig_req;       // From DUT
  logic [1:0] dma_trig_req_type;  // From DUT
  logic       dma_trig_ack;       // From Testbench
  logic [1:0] dma_trig_ack_type;  // From Testbench

  clocking master_cb @(posedge clk);
    default input #1step output #1ns;

    input  dma_trig_req;
    input  dma_trig_req_type;

    output dma_trig_ack;
    output dma_trig_ack_type;
  endclocking

  clocking monitor_cb @(posedge clk);
    default input #1step;
    input dma_trig_req;
    input dma_trig_req_type;
    input dma_trig_ack;
    input dma_trig_ack_type;
  endclocking
  
  task monitor_dma_req(output bit [1:0] trig_type);
      `uvm_info("DMA_IF_MON", "Waiting for dma_trig_req to be asserted by DUT...", UVM_MEDIUM)
      while (dma_trig_req !== 1'b1) begin
          @(posedge clk);
      end
      trig_type = dma_trig_req_type; 
      `uvm_info("DMA_IF_MON", $sformatf("SUCCESS: dma_trig_req sampled HIGH! Captured type: 2'b%0b", trig_type), UVM_MEDIUM)
  endtask

  task drive_dma_ack(input bit [1:0] ack_type);
      dma_trig_ack      <= 1'b1;
      dma_trig_ack_type <= ack_type;
      `uvm_info("DMA_IF_DRV", "Acknowledge driven. Waiting for DUT to drop dma_trig_req ...", UVM_MEDIUM) 
      while (dma_trig_req === 1'b1) begin
          @(posedge clk);
      end
      `uvm_info("DMA_IF_DRV", "DUT dropped request. Clearing dma_trig_ack to LOW...", UVM_MEDIUM) 
      dma_trig_ack      <= 1'b0;
      dma_trig_ack_type <= 2'b00;
      @(posedge clk); 
  endtask
endinterface: dma_trig_cam_cntrl_if

