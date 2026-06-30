`ifndef CAMERA_SS_ENV_SV
`define CAMERA_SS_ENV_SV

class camera_ss_env extends uvm_env;
    `uvm_component_utils(camera_ss_env)

    // 1. Component Handles
    dvp_env               dvp_ip_env;
    apb_env               apb_vip_env; 
    camera_vsequencer     vsqr;        

    function new(string name = "camera_ss_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 2. Configure the APB VIP
        begin
            apb_env_config apb_cfg;
            apb_cfg = apb_env_config::type_id::create("apb_cfg");
            
            apb_cfg.has_master = 1; 
            apb_cfg.has_slave  = 0; 
            
            uvm_config_db#(apb_env_config)::set(this, "apb_vip_env*", "apb_cfg", apb_cfg);
        end

        // 3. Build Components
        dvp_ip_env  = dvp_env::type_id::create("dvp_ip_env", this);
        apb_vip_env = apb_env::type_id::create("apb_vip_env", this);
        vsqr        = camera_vsequencer::type_id::create("vsqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);

     // 1. Link DVP physical sequencer
       vsqr.dvp_seqr = dvp_ip_env.dvp_agt.sequencer;
    
     // 2. Link APB physical sequencer directly through the AGENT
       vsqr.apb_seqr = apb_vip_env.master_agent.sequencer; 
   endfunction

endclass : camera_ss_env

`endif // CAMERA_SS_ENV_SV

