`ifndef CAMERA_IP_VSEQUENCER_SV
`define CAMERA_IP_VSEQUENCER_SV

class camera_ip_vsequencer extends uvm_sequencer;
    `uvm_component_utils(camera_ip_vsequencer)

    apb_sequencer  apb_seqr;  
    dvp_sequencer  dvp_seqr;  
    axi_sequencer  axi_seqr;  
    virtual camera_dvp_if vif;

    function new(string name = "camera_ip_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual camera_dvp_if)::get(this, "", "dvp_vif", vif)) begin
            `uvm_info(get_type_name(), "Virtual interface not set for vsequencer (Ignored if not needed)", UVM_HIGH)
        end
    endfunction : build_phase

endclass : camera_ip_vsequencer

`endif // CAMERA_IP_VSEQUENCER_SV

