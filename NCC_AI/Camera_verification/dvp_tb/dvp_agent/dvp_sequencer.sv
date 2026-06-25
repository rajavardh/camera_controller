`ifndef DVP_SEQUENCER_SV
`define DVP_SEQUENCER_SV

class dvp_sequencer extends uvm_sequencer #(dvp_seq_item);
  
  // Register with the UVM Factory
  `uvm_component_utils(dvp_sequencer)

  // Standard constructor
  function new(string name = "dvp_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : dvp_sequencer

`endif // DVP_SEQUENCER_SV
