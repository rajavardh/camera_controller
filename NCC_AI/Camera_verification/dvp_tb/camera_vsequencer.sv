`ifndef CAMERA_VSEQUENCER_SV
`define CAMERA_VSEQUENCER_SV

class camera_vsequencer extends uvm_sequencer;
    `uvm_component_utils(camera_vsequencer)

    // Using physical sequencers and matching handle names
    apb_master_sequencer apb_seqr; 
    dvp_sequencer        dvp_seqr; 

    // axi_sequencer     axi_seqr; 

    //  required for the wrapper sequence override
    apb_master_agent_config apb_master_agent_cfg_h;

    function new(string name = "camera_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

endclass : camera_vsequencer

`endif // CAMERA_VSEQUENCER_SV
