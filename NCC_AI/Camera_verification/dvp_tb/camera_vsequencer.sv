`ifndef CAMERA_VSEQUENCER_SV
`define CAMERA_VSEQUENCER_SV

class camera_vsequencer extends uvm_sequencer;
    `uvm_component_utils(camera_ip_vsequencer)

    apb_master_vsequencerr apb_vsqr; // Handle to the VIP's 
    dvp_sequencer         dvp_seqr; 

//    axi_sequencer         axi_seqr; 

    function new(string name = "camera_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
endclass : camera_ip_vsequencer

`endif
