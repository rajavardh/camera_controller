interface apb_cam_cntrl_if (input logic pclk, input logic presetn);

  logic [2:0]  pprot;
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [3:0]  pstrb;
  logic [31:0] paddr;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic        pslverr;
  logic        pready;


  clocking master_cb @(posedge pclk);
    default input #1step output #1ns;

    output pprot;
    output psel;
    output penable;
    output pwrite;
    output pstrb;
    output paddr;
    output pwdata;

    input  prdata;
    input  pslverr;
    input  pready;
  endclocking


  clocking monitor_cb @(posedge pclk);
    default input #1step;

    input pprot;
    input psel;
    input penable;
    input pwrite;
    input pstrb;
    input paddr;
    input pwdata;
    input prdata;
    input pslverr;
    input pready;
  endclocking

endinterface: apb_cam_cntrl_if

