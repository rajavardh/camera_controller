`ifndef DVP_ENV_SV
`define DVP_ENV_SV

class dvp_env extends uvm_env;

  dvp_agent      dvp_agt;
  dvp_scoreboard scb;
  dvp_subscriber sub;

  `uvm_component_utils(dvp_env)

  function new(string name = "dvp_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    dvp_agt = dvp_agent::type_id::create("dvp_agt", this);
    scb     = dvp_scoreboard::type_id::create("scb", this);
    sub     = dvp_subscriber::type_id::create("sub", this);
  endfunction

  // Connect Phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    dvp_agt.monitor.cam_ap.connect(scb.cam_export);
    dvp_agt.monitor.cam_ap.connect(sub.cam_export);
    
  endfunction

endclass : dvp_env

`endif // DVP_ENV_SV
