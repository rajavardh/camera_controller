`ifndef DVP_SUBSCRIBER_SV
`define DVP_SUBSCRIBER_SV

class dvp_subscriber extends uvm_component;

  uvm_analysis_imp #(dvp_seq_item, dvp_subscriber) cam_export;

  `uvm_component_utils(dvp_subscriber)

  function new(string name = "dvp_subscriber", uvm_component parent = null);
    super.new(name, parent);
    cam_export = new("cam_export", this);
  endfunction

  // The Write Function 
  virtual function void write(dvp_seq_item item);
    `uvm_info("DVP_SUB", $sformatf("SUCCESS! Subscriber received Line %0d for coverage.", item.line_count), UVM_HIGH)
    
    // logic
  endfunction

endclass : dvp_subscriber

`endif // DVP_SUBSCRIBER_SV
