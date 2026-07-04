`ifndef DVP_AGENT_SV
`define DVP_AGENT_SV

class dvp_agent extends uvm_agent;

    dvp_sequencer sequencer;
    dvp_driver    driver;
    dvp_monitor   monitor;

    `uvm_component_utils(dvp_agent)

    function new(string name = "dvp_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 1. Unconditionally build the monitor!
        monitor = dvp_monitor::type_id::create("monitor", this);

        // 2. Conditionally build driver and sequencer
        if (get_is_active() == UVM_ACTIVE) begin
            `uvm_info("DVP_AGENT", "Building DVP Agent in ACTIVE mode.", UVM_LOW)
            sequencer = dvp_sequencer::type_id::create("sequencer", this);
            driver    = dvp_driver::type_id::create("driver", this);
        end else begin
            `uvm_info("DVP_AGENT", "Building DVP Agent in PASSIVE mode.", UVM_LOW)
        end
    endfunction

    // Connect Phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass : dvp_agent

`endif // DVP_AGENT_SV
