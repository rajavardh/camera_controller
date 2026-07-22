`ifndef CAMERA_VSEQUENCER_SV
`define CAMERA_VSEQUENCER_SV

class camera_vsequencer extends uvm_sequencer;
    `uvm_component_utils(camera_vsequencer)

    apb_master_sequencer apb_seqr;
    dvp_sequencer        dvp_seqr;
    dma_sequencer        dma_seqr; 
   
    axi4_master_write_sequencer axi_wr_seqr; 
    axi4_master_read_sequencer  axi_rd_seqr; 

    apb_master_agent_config apb_master_agent_cfg_h;

    virtual dma_trig_cam_cntrl_if vif_dma;

    function new(string name = "camera_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
endclass : camera_vsequencer

`endif // CAMERA_VSEQUENCER_SV
