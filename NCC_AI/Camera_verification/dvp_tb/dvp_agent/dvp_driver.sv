`ifndef DVP_DRIVER_SV
`define DVP_DRIVER_SV

class dvp_driver extends uvm_driver #(dvp_seq_item);
    `uvm_component_utils(dvp_driver)

    virtual camera_dvp_if vif;

    function new(string name = "dvp_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Ensure name perfectly matches what is set in top.sv
        if (!uvm_config_db#(virtual camera_dvp_if)::get(this, "", "dvp_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Failed to extract virtual camera_dvp_if from uvm_config_db!")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        reset_dvp_interface();

        forever begin
            seq_item_port.get_next_item(req);
            
           `uvm_info("dvp_driver", $sformatf("Driving Line ID: %0d | Resolution Width: %0d | Format: %s", req.line_id, req.pixels_per_line, req.format_cfg.name()), UVM_LOW)
            
            drive_line(req); 
            
            seq_item_port.item_done();
        end
    endtask : run_phase

    task reset_dvp_interface();
        vif.cb_drv.dvp_vsync <= 1'b0; // Updated to cb_drv
        vif.cb_drv.dvp_href  <= 1'b0;
        vif.cb_drv.dvp_data  <= 8'h00;
        @(vif.cb_drv);
    endtask : reset_dvp_interface

    task drive_line(dvp_seq_item item);

        // ---------------------------------------------------------
        // 1. Vertical Timing (Only happens if this is Line 0)
        // ---------------------------------------------------------
        if (item.is_start_of_frame == 1'b1) begin
            
            vif.cb_drv.dvp_vsync <= 1'b1;
            repeat(item.v_pulse_cycles) @(vif.cb_drv); // Corrected variable
            
            vif.cb_drv.dvp_vsync <= 1'b0;
            repeat(item.v_blank_cycles) @(vif.cb_drv); // Wait back porch delay
            
        end

        // ---------------------------------------------------------
        // 2. Horizontal Active Line (Happens for every sequence item)
        // ---------------------------------------------------------
        vif.cb_drv.dvp_href <= 1'b1;
        
        // The array is already perfectly sized by the constraints solver!
        // We just loop through whatever is inside it.
        foreach (item.dvp_data_bytes[i]) begin
            vif.cb_drv.dvp_data <= item.dvp_data_bytes[i];
            @(vif.cb_drv); 
        end
        
        // ---------------------------------------------------------
        // 3. Horizontal Blanking 
        // ---------------------------------------------------------
        vif.cb_drv.dvp_href <= 1'b0;
        vif.cb_drv.dvp_data <= 8'h00; // Clean the bus
        
        repeat(item.h_blank_cycles) @(vif.cb_drv); 
        
    endtask : drive_line

endclass : dvp_driver

`endif // DVP_DRIVER_SV
