`ifndef CAMERA_BASE_TEST_SV
`define CAMERA_BASE_TEST_SV

class camera_base_test extends uvm_test;
  `uvm_component_utils(camera_base_test)

  camera_ss_env env;

  function new(string name = "camera_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = camera_ss_env::type_id::create("env", this);
  endfunction

  // Run Phase
  virtual task run_phase(uvm_phase phase);
    camera_vseq vseq;

    phase.raise_objection(this, "Starting Camera Subsystem Test");
    
    vseq = camera_vseq::type_id::create("vseq");
    
    `uvm_info("TEST", "Starting Subsystem Virtual Sequence (APB Config + DVP Stream)...", UVM_LOW)
     vseq.start(env.v_seqr);
    
    `uvm_info("TEST", "Subsystem sequence complete. Dropping objection.", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology(); 
  endfunction

endclass : camera_base_test

`endif // CAMERA_BASE_TEST_SV
