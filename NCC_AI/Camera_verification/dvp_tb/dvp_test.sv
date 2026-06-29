`ifndef DVP_BASE_TEST_SV
`define DVP_BASE_TEST_SV

class dvp_test extends uvm_test;
  `uvm_component_utils(dvp_base_test)

  dvp_env env;

  function new(string name = "dvp_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = dvp_env::type_id::create("env", this);
  endfunction

  // Run Phase
  virtual task run_phase(uvm_phase phase);
    dvp_sequence seq;
    phase.raise_objection(this, "Starting DVP Standalone Test");
    seq = dvp_sequence::type_id::create("seq");
    `uvm_info("DVP_TEST", "Starting standalone DVP camera frame generation...", UVM_LOW)
    seq.start(env.dvp_agt.sequencer);
    `uvm_info("DVP_TEST", "Camera frame complete. Dropping objection.", UVM_LOW)
    phase.drop_objection(this);
  endtask

  // Topology Check
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : dvp_base_test

`endif // DVP_BASE_TEST_SV
