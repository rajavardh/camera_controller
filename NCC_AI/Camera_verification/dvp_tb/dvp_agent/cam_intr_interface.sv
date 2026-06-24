interface intr_cam_cntrl_if (input logic clk, input logic reset_n);

  logic       intr_line_tx_dn;   
  logic       intr_line_in_dn;   
  logic       intr_frm_tx_dn;    
  logic       intr_buf_over_err; 
  logic       intr_buf_undr_err; 

  clocking monitor_cb @(posedge clk);
    default input #1step;
    input intr_line_tx_dn;
    input intr_line_in_dn;
    input intr_frm_tx_dn;
    input intr_buf_over_err;
    input intr_buf_undr_err;
  endclocking

endinterface: intr_cam_cntrl_if

