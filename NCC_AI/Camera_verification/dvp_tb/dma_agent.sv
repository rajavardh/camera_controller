
class dma_agent extends uvm_agent;
    `uvm_component_utils(dma_agent)

    dma_driver    driver;
    dma_sequencer sequencer;
    virtual dma_trig_cam_cntrl_if vif;

    function new(string name = "dma_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual dma_trig_cam_cntrl_if)::get(this, "", "vif_dma", vif)) begin
            `uvm_fatal("DMA_AGT_ERR", "Virtual interface handle  missing from config_db!")
        end

        if (is_active == UVM_ACTIVE) begin
            driver    = dma_driver::type_id::create("driver", this);
            sequencer = dma_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            driver.vif = this.vif;
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass

