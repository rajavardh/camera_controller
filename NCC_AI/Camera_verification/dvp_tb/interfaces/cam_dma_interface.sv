`timescale 1ns/1ps

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

endinterface: dma_trig_cam_cntrl_if

