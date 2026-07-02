`ifndef CAMERA_SS_ENV_SV
`define CAMERA_SS_ENV_SV

class camera_ss_env extends uvm_env;
    `uvm_component_utils(camera_ss_env)

    // 1. Component Handles
    dvp_env            dvp_ip_env;
    apb_env            apb_vip_env; 
    camera_vsequencer  v_seqr;    
    
    //declare this here so both build_phase and connect_phase can see it!
    apb_env_config     apb_cfg;  

    function new(string name = "camera_ss_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 2. Configure the APB VIP
        begin
            apb_cfg = apb_env_config::type_id::create("apb_cfg");
            
            apb_cfg.has_scoreboard   = 0; 
            apb_cfg.has_virtual_seqr = 0; 
            apb_cfg.no_of_slaves     = 0; // VIP should build 0 slave agents

            // Configure the Master Agent
            apb_cfg.apb_master_agent_cfg_h = apb_master_agent_config::type_id::create("apb_master_agent_cfg_h");
            
            apb_cfg.apb_master_agent_cfg_h.is_active = UVM_ACTIVE; 
            
            // Tell the Master Agent it is communicating with 1 physical slave (the DUT)
            apb_cfg.apb_master_agent_cfg_h.no_of_slaves = 1; 

            // IMPORTANT: Feed the VIP the memory map of your Camera IP!
            // SLAVE 0 gets the CAMERA_Base address range
            apb_cfg.apb_master_agent_cfg_h.master_min_addr_range(0, 32'h07109000); 
            apb_cfg.apb_master_agent_cfg_h.master_max_addr_range(0, 32'h07109FFF); 
            
            uvm_config_db#(apb_env_config)::set(this, "apb_vip_env*", "apb_env_config", apb_cfg);
        end

        // 3. Build Components
        dvp_ip_env  = dvp_env::type_id::create("dvp_ip_env", this);
        apb_vip_env = apb_env::type_id::create("apb_vip_env", this);
        v_seqr      = camera_vsequencer::type_id::create("v_seqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // 1. Link physical sequencers to the virtual sequencer
        v_seqr.dvp_seqr = dvp_ip_env.dvp_agt.sequencer;
        v_seqr.apb_seqr = apb_vip_env.master_agent.sequencer; 
        
        v_seqr.apb_master_agent_cfg_h = apb_cfg.apb_master_agent_cfg_h; 
    endfunction

endclass : camera_ss_env

`endif // CAMERA_SS_ENV_SV
