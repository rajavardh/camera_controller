`ifndef CAMERA_BASE_TEST_SV
`define CAMERA_BASE_TEST_SV

class camera_base_test extends uvm_test;
   `uvm_component_utils(camera_base_test)

   camera_ss_env env;
   camera_report_server srv;
   cam_resolution_e test_res = RES_QVGA;
   cam_format_e     test_fmt = FMT_RGB888;
   
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
      
      phase.phase_done.set_drain_time(this, 2us); 

      vseq = camera_vseq::type_id::create("vseq");

      `uvm_info("TEST", "Configuring virtual sequence hardware control knobs via constraints...", UVM_LOW)
      
      if (!vseq.randomize() with {
         vseq_res      == local::test_res;
         vseq_fmt      == local::test_fmt;
         axi_base_addr == 32'h0800_0080; // Corrected SoC Dump base address mapping
      }) begin
         `uvm_error("TEST_RAND_ERR", "Virtual sequence configuration randomization failed!")
      end

      `uvm_info("TEST", $sformatf("Starting Subsystem Virtual Sequence (Resolution: %s, Format: %s)...",
                                  vseq.vseq_res.name(), vseq.vseq_fmt.name()), UVM_LOW)

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

