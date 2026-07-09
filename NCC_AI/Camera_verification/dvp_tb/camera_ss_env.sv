`ifndef CAMERA_SS_ENV_SV
`define CAMERA_SS_ENV_SV

class camera_ss_env extends uvm_env;
    `uvm_component_utils(camera_ss_env)

    // Environment handles
    dvp_env               dvp_ip_env;
    apb_env               apb_vip_env;
    axi4_master_agent     axi_vip_env;
    camera_vsequencer     v_seqr;

    // Configuration handles
    apb_env_config           apb_cfg;
    axi4_master_agent_config axi_cfg;

    function new(string name = "camera_ss_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 1. Configure the APB VIP
        apb_cfg = apb_env_config::type_id::create("apb_cfg");
        apb_cfg.has_scoreboard   = 1; 
        apb_cfg.has_virtual_seqr = 0;
        apb_cfg.no_of_slaves     = 0;
        
        apb_cfg.apb_master_agent_cfg_h = apb_master_agent_config::type_id::create("apb_master_agent_cfg_h");
        apb_cfg.apb_master_agent_cfg_h.is_active = UVM_ACTIVE;
        apb_cfg.apb_master_agent_cfg_h.no_of_slaves = 1;
        apb_cfg.apb_master_agent_cfg_h.master_min_addr_range(0, 32'h07109000);
        apb_cfg.apb_master_agent_cfg_h.master_max_addr_range(0, 32'h07109FFF);

        uvm_config_db#(apb_env_config)::set(this, "*", "apb_env_config", apb_cfg);
        uvm_config_db#(apb_master_agent_config)::set(this, "*", "apb_master_agent_config", apb_cfg.apb_master_agent_cfg_h);

        // ---------------------------------------------------------
        // 2. Configure the AXI VIP
        // ---------------------------------------------------------
        axi_cfg = axi4_master_agent_config::type_id::create("axi_cfg");
        axi_cfg.is_active = UVM_ACTIVE;
        
        // ---> VIP BUG WORKAROUND: Force coverage to build so the VIP doesn't crash <---
        axi_cfg.has_coverage = 1; 

        // 3. Build Components
        dvp_ip_env  = dvp_env::type_id::create("dvp_ip_env", this);
        apb_vip_env = apb_env::type_id::create("apb_vip_env", this);
        axi_vip_env = axi4_master_agent::type_id::create("axi_vip_env", this);

        // ---> RESTORED: Manual assignment is required for this specific VIP <---
        axi_vip_env.axi4_master_agent_cfg_h = axi_cfg;

        v_seqr = camera_vsequencer::type_id::create("v_seqr", this);
    endfunction
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // APB & DVP Connections
        v_seqr.apb_seqr = apb_vip_env.apb_master_agent_h.apb_master_seqr_h;
        v_seqr.dvp_seqr = dvp_ip_env.dvp_agt.sequencer;

        // AXI Dual-Sequencer Connections
        v_seqr.axi_wr_seqr = axi_vip_env.axi4_master_write_seqr_h;
        v_seqr.axi_rd_seqr = axi_vip_env.axi4_master_read_seqr_h;
        
        // Pass the DMA interface to the virtual sequencer
        if (!uvm_config_db#(virtual dma_trig_cam_cntrl_if)::get(this, "", "vif_dma", v_seqr.vif_dma)) begin
            `uvm_error("ENV", "Could not find vif_dma in config_db! Sequence trigger won't work.")
        end
    endfunction
endclass : camera_ss_env

`endif // CAMERA_SS_ENV_SV
