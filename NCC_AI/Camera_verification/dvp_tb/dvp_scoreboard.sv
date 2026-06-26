`ifndef DVP_SCOREBOARD_SV
`define DVP_SCOREBOARD_SV

class dvp_scoreboard extends uvm_scoreboard;

  // Analysis Import port to receive items from the Monitor
  uvm_analysis_imp #(dvp_seq_item, dvp_scoreboard) cam_export;

  `uvm_component_utils(dvp_scoreboard)

  function new(string name = "dvp_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    cam_export = new("cam_export", this);
  endfunction

  // The Write Function 

  virtual function void write(dvp_seq_item item);
    `uvm_info("DVP_SCB", $sformatf("SUCCESS! Scoreboard received Line %0d. Format: %s",item.line_count, item.format_cfg.name()), UVM_MEDIUM)
    
    // logic for comparision 
  endfunction

endclass : dvp_scoreboard

`endif // DVP_SCOREBOARD_SV
