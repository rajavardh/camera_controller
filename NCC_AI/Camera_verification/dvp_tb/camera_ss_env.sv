`ifndef CAMERA_SS_ENV_SV
`define CAMERA_SS_ENV_SV

class camera_ss_env extends uvm_env;
    `uvm_component_utils(camera_ss_env)

    // 1. Component Handles
    dvp_env            dvp_ip_env;
    apb_env            apb_vip_env; 
    camera_vsequencer  v_seqr;    
    
    apb_env_config     apb_cfg;  

    function new(string name = "camera_ss_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 2. Configure the APB VIP
        begin
            apb_cfg = apb_env_config::type_id::create("apb_cfg");
            
            apb_cfg.has_scoreboard   = 1; 
            apb_cfg.has_virtual_seqr = 0; 
            apb_cfg.no_of_slaves     = 0; 

            // Configure the Master Agent
            apb_cfg.apb_master_agent_cfg_h = apb_master_agent_config::type_id::create("apb_master_agent_cfg_h");
            apb_cfg.apb_master_agent_cfg_h.is_active = UVM_ACTIVE; 
            apb_cfg.apb_master_agent_cfg_h.no_of_slaves = 1; 

            // Memory Map
            apb_cfg.apb_master_agent_cfg_h.master_min_addr_range(0, 32'h07109000); 
            apb_cfg.apb_master_agent_cfg_h.master_max_addr_range(0, 32'h07109FFF); 
            
            // ====================================================================
            // NUCLEAR OPTION: Global config_db set 
            // ====================================================================
            uvm_config_db#(apb_env_config)::set(null, "*", "apb_env_config", apb_cfg);
            uvm_config_db#(apb_master_agent_config)::set(null, "*", "apb_master_agent_config", apb_cfg.apb_master_agent_cfg_h);
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
 
        v_seqr.apb_seqr = apb_vip_env.apb_master_agent_h.apb_master_seqr_h;
        v_seqr.apb_master_agent_cfg_h = apb_cfg.apb_master_agent_cfg_h; 
    endfunction

endclass : camera_ss_env

`endif // CAMERA_SS_ENV_SV
