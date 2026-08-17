`ifndef CAMERA_BASE_TEST_SV
`define CAMERA_BASE_TEST_SV

class camera_base_test extends uvm_test;
   `uvm_component_utils(camera_base_test)

   camera_ss_env env;
   cam_resolution_e test_res;
   cam_format_e     test_fmt;
   
   function new(string name = "camera_base_test", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      int tmp_fmt, tmp_res;
      super.build_phase(phase);
      
      // 1. Resolve configuration at Time 0
      if ($value$plusargs("FMT=%d", tmp_fmt)) test_fmt = cam_format_e'(tmp_fmt);
      else test_fmt = cam_format_e'($urandom_range(0, 3));
      
      if ($value$plusargs("RES=%d", tmp_res)) test_res = cam_resolution_e'(tmp_res);
      else test_res = cam_resolution_e'($urandom_range(0, 3));
      
      // 2. Broadcast to ALL components before they build!
      uvm_config_db#(cam_format_e)::set(this, "*", "cfg_fmt", test_fmt);
      uvm_config_db#(cam_resolution_e)::set(this, "*", "cfg_res", test_res);

      env = camera_ss_env::type_id::create("env", this);
   endfunction

   virtual task run_phase(uvm_phase phase);
      camera_vseq vseq;

      phase.raise_objection(this, "Starting Camera Subsystem Test");
      phase.phase_done.set_drain_time(this, 2us); 

      vseq = camera_vseq::type_id::create("vseq");

      // 3. Force the virtual sequence to use our unified knobs
      if (!vseq.randomize() with {
         vseq_res      == local::test_res;
         vseq_fmt      == local::test_fmt;
         axi_base_addr == 32'h0000_0000; 
      }) begin
         `uvm_error("TEST_RAND_ERR", "Virtual sequence config failed!")
      end

      `uvm_info("TEST", $sformatf("Starting Unified Subsystem Sequence (Res: %s, Fmt: %s)...",vseq.vseq_res.name(), vseq.vseq_fmt.name()), UVM_LOW)

      vseq.start(env.v_seqr);
      phase.drop_objection(this);
   endtask

   virtual function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      env.axi_vip_env.axi4_master_drv_proxy_h.set_report_id_verbosity("axi4_master_driver_proxy", UVM_LOW);
   endfunction

endclass : camera_base_test
`endif // CAMERA_BASE_TEST_SV
