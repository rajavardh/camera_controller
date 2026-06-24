interface axi_s_cam_cntrl_if (input logic clk, input logic reset);


  // AXI Slave Read Request Channel
  logic [13:0]  i_axi_s_cam_cntrl_araddr;
  logic [1:0]   i_axi_s_cam_cntrl_arburst;
  logic [11:0]  i_axi_s_cam_cntrl_arid;
  logic [7:0]   i_axi_s_cam_cntrl_arlen;
  logic         o_axi_s_cam_cntrl_arready;
  logic [2:0]   i_axi_s_cam_cntrl_arsize;
  logic         i_axi_s_cam_cntrl_arvalid;
  logic         i_axi_s_cam_cntrl_arlock;
  logic [2:0]   i_axi_s_cam_cntrl_arprot;
  logic [3:0]   i_axi_s_cam_cntrl_arqos;

  // AXI Slave Write Request Channel
  logic [13:0]  i_axi_s_cam_cntrl_awaddr;
  logic         i_axi_s_cam_cntrl_awakeup;
  logic [1:0]   i_axi_s_cam_cntrl_awburst;
  logic [11:0]  i_axi_s_cam_cntrl_awid;
  logic [7:0]   i_axi_s_cam_cntrl_awlen;
  logic         o_axi_s_cam_cntrl_awready;
  logic [2:0]   i_axi_s_cam_cntrl_awsize;
  logic         i_axi_s_cam_cntrl_awvalid;
  logic         i_axi_s_cam_cntrl_awlock;
  logic [2:0]   i_axi_s_cam_cntrl_awprot;
  logic [3:0]   i_axi_s_cam_cntrl_awqos;

  // AXI Slave Write Data Channel
  logic [127:0] i_axi_s_cam_cntrl_wdata;
  logic         i_axi_s_cam_cntrl_wlast;
  logic         o_axi_s_cam_cntrl_wready;
  logic [15:0]  i_axi_s_cam_cntrl_wstrb;
  logic         i_axi_s_cam_cntrl_wvalid;
  logic [1:0]   i_axi_s_cam_cntrl_wpoison;

  // AXI Slave Write Response Channel
  logic [11:0]  o_axi_s_cam_cntrl_bid;
  logic         i_axi_s_cam_cntrl_bready;
  logic [1:0]   o_axi_s_cam_cntrl_bresp;
  logic         o_axi_s_cam_cntrl_bvalid;

  // AXI Slave Read Response Channel
  logic [127:0] o_axi_s_cam_cntrl_rdata;
  logic [11:0]  o_axi_s_cam_cntrl_rid;
  logic         o_axi_s_cam_cntrl_rlast;
  logic         i_axi_s_cam_cntrl_rready;
  logic [1:0]   o_axi_s_cam_cntrl_rresp;
  logic         o_axi_s_cam_cntrl_rvalid;
  logic [1:0]   o_axi_s_cam_cntrl_rpoison;


  clocking master_cb @(posedge clk);
    default input #1step output #1ns;

    output i_axi_s_cam_cntrl_araddr;
    output i_axi_s_cam_cntrl_arburst;
    output i_axi_s_cam_cntrl_arid;
    output i_axi_s_cam_cntrl_arlen;
    input  o_axi_s_cam_cntrl_arready;
    output i_axi_s_cam_cntrl_arsize;
    output i_axi_s_cam_cntrl_arvalid;
    output i_axi_s_cam_cntrl_arlock;
    output i_axi_s_cam_cntrl_arprot;
    output i_axi_s_cam_cntrl_arqos;

    output i_axi_s_cam_cntrl_awaddr;
    output i_axi_s_cam_cntrl_awakeup;
    output i_axi_s_cam_cntrl_awburst;
    output i_axi_s_cam_cntrl_awid;
    output i_axi_s_cam_cntrl_awlen;
    input  o_axi_s_cam_cntrl_awready;
    output i_axi_s_cam_cntrl_awsize;
    output i_axi_s_cam_cntrl_awvalid;
    output i_axi_s_cam_cntrl_awlock;
    output i_axi_s_cam_cntrl_awprot;
    output i_axi_s_cam_cntrl_awqos;

    output i_axi_s_cam_cntrl_wdata;
    output i_axi_s_cam_cntrl_wlast;
    input  o_axi_s_cam_cntrl_wready;
    output i_axi_s_cam_cntrl_wstrb;
    output i_axi_s_cam_cntrl_wvalid;
    output i_axi_s_cam_cntrl_wpoison;

    input  o_axi_s_cam_cntrl_bid;
    output i_axi_s_cam_cntrl_bready;
    input  o_axi_s_cam_cntrl_bresp;
    input  o_axi_s_cam_cntrl_bvalid;

    input  o_axi_s_cam_cntrl_rdata;
    input  o_axi_s_cam_cntrl_rid;
    input  o_axi_s_cam_cntrl_rlast;
    output i_axi_s_cam_cntrl_rready;
    input  o_axi_s_cam_cntrl_rresp;
    input  o_axi_s_cam_cntrl_rvalid;
    input  o_axi_s_cam_cntrl_rpoison;
  endclocking


  // =========================================================================
  clocking monitor_cb @(posedge clk);
    default input #1step;

    input i_axi_s_cam_cntrl_araddr;
    input i_axi_s_cam_cntrl_arburst;
    input i_axi_s_cam_cntrl_arid;
    input i_axi_s_cam_cntrl_arlen;
    input o_axi_s_cam_cntrl_arready;
    input i_axi_s_cam_cntrl_arsize;
    input i_axi_s_cam_cntrl_arvalid;
    input i_axi_s_cam_cntrl_arlock;
    input i_axi_s_cam_cntrl_arprot;
    input i_axi_s_cam_cntrl_arqos;

    input i_axi_s_cam_cntrl_awaddr;
    input i_axi_s_cam_cntrl_awakeup;
    input i_axi_s_cam_cntrl_awburst;
    input i_axi_s_cam_cntrl_awid;
    input i_axi_s_cam_cntrl_awlen;
    input o_axi_s_cam_cntrl_awready;
    input i_axi_s_cam_cntrl_awsize;
    input i_axi_s_cam_cntrl_awvalid;
    input i_axi_s_cam_cntrl_awlock;
    input i_axi_s_cam_cntrl_awprot;
    input i_axi_s_cam_cntrl_awqos;

    input i_axi_s_cam_cntrl_wdata;
    input i_axi_s_cam_cntrl_wlast;
    input o_axi_s_cam_cntrl_wready;
    input i_axi_s_cam_cntrl_wstrb;
    input i_axi_s_cam_cntrl_wvalid;
    input i_axi_s_cam_cntrl_wpoison;

    input o_axi_s_cam_cntrl_bid;
    input i_axi_s_cam_cntrl_bready;
    input o_axi_s_cam_cntrl_bresp;
    input o_axi_s_cam_cntrl_bvalid;

    input o_axi_s_cam_cntrl_rdata;
    input o_axi_s_cam_cntrl_rid;
    input o_axi_s_cam_cntrl_rlast;
    input i_axi_s_cam_cntrl_rready;
    input o_axi_s_cam_cntrl_rresp;
    input o_axi_s_cam_cntrl_rvalid;
    input o_axi_s_cam_cntrl_rpoison;
  endclocking

endinterface: axi_s_cam_cntrl_if

