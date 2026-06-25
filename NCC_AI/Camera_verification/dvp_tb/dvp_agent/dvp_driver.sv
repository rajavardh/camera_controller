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
        if (!uvm_config_db#(virtual camera_dvp_if)::get(this, "", "dvp_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Failed to extract virtual camera_dvp_if from uvm_config_db!")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        reset_dvp_interface();

        forever begin
            seq_item_port.get_next_item(req);
            
            `uvm_info(get_type_name(), $sformatf("Launching frame transfer. Geometry: [%0dx%0d] | Format: %s", 
                      req.pixels_per_line, req.line_count, (req.is_rgb ? "RGB" : "YUV")), UVM_LOW)
            
            drive_frame(req);
            
            seq_item_port.item_done();
        end
    endtask : run_phase


    task reset_dvp_interface();
        vif.cb_tb.dvp_vsync <= 1'b0;
        vif.cb_tb.dvp_href  <= 1'b0;
        vif.cb_tb.dvp_data  <= 8'h00;
        @(vif.cb_tb);
    endtask : reset_dvp_interface

    task drive_frame(dvp_seq_item item);

        vif.cb_tb.dvp_vsync <= 1'b1;
        repeat(item.v_blank_cycles) @(vif.cb_tb); 
        vif.cb_tb.dvp_vsync <= 1'b0;
        repeat(5) @(vif.cb_tb);  

        case (item.is_rgb)
            1 :      drive_rgb888(item);
            default:     `uvm_error(get_type_name(), $sformatf("Encountered unsupported is_rgb: %s", (item.is_rgb ? "RGB" : "YUV")))
        endcase
        
    endtask : drive_frame

    task drive_rgb888(dvp_seq_item item);
        int byte_idx = 0;
        int valid_line_bytes = item.pixels_per_line*3; // 3 bytes per pixel
        
        for (int i = 0; i < item.line_count; i++) begin //320*240
            vif.cb_tb.dvp_href <= 1'b1;
            
            for (int j = 0; j < valid_line_bytes; j++) begin
                vif.cb_tb.dvp_data <= item.dvp_data_bytes[byte_idx++];
                @(vif.cb_tb); 
            end
            
            vif.cb_tb.dvp_href <= 1'b0;
            vif.cb_tb.dvp_data <= 8'h00;
            repeat(item.h_blank_cycles) @(vif.cb_tb); 
        end
    endtask : drive_rgb888


endclass : dvp_driver

`endif // DVP_DRIVER_SV

