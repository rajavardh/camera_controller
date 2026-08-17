`ifndef DVP_MONITOR_SV
`define DVP_MONITOR_SV

class dvp_monitor extends uvm_monitor;

    virtual camera_dvp_if dvp_vif;
  
    uvm_analysis_port #(dvp_seq_item) cam_ap;
  
    // 1. Add Configuration Tracking Variables
    cam_format_e     cfg_fmt;
    cam_resolution_e cfg_res;

    `uvm_component_utils(dvp_monitor)
  
    function new(string name = "dvp_monitor", uvm_component parent = null);
        super.new(name, parent);
        cam_ap = new("cam_ap", this); 
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db #(virtual camera_dvp_if)::get(this, "", "dvp_vif", dvp_vif)) begin
            `uvm_fatal("DVP_MON", "Virtual interface dvp_vif not found in config_db! Ensure top.sv sets it correctly.")
        end
        
        // 2. Extract the randomized knobs from the test level
        if(!uvm_config_db #(cam_format_e)::get(this, "", "cfg_fmt", cfg_fmt)) begin
            `uvm_warning("DVP_MON", "cfg_fmt not found in config_db, defaulting to FMT_RGB888")
            cfg_fmt = FMT_RGB888;
        end
        
        if(!uvm_config_db #(cam_resolution_e)::get(this, "", "cfg_res", cfg_res)) begin
            `uvm_warning("DVP_MON", "cfg_res not found in config_db, defaulting to RES_QVGA")
            cfg_res = RES_QVGA;
        end
    endfunction
      
    task run_phase(uvm_phase phase);
        dvp_seq_item item;          
        bit [7:0]    byte_queue[$]; 
    
        int v_pulse_cnt = 0; 
        int v_blank_cnt = 0;
        int h_blank_cnt = 0;
        bit seen_vsync  = 0;

        `uvm_info("DVP_MON", "Starting DVP Monitor observation loop...", UVM_LOW)

        forever begin
            @(dvp_vif.cb_mon);

            if (dvp_vif.cb_mon.dvp_vsync === 1'b1) begin
                seen_vsync = 1'b1;
                v_pulse_cnt++;
                v_blank_cnt = 0; 
                h_blank_cnt = 0;
            end
      
            else if (dvp_vif.cb_mon.dvp_href === 1'b0) begin
                if (seen_vsync == 1'b1) begin
                    v_blank_cnt++; 
                end else begin
                    h_blank_cnt++; 
                end
            end
      
            else if (dvp_vif.cb_mon.dvp_href === 1'b1) begin
                byte_queue.delete();

                while (dvp_vif.cb_mon.dvp_href === 1'b1) begin
                    byte_queue.push_back(dvp_vif.cb_mon.dvp_data);
                    @(dvp_vif.cb_mon);
                end

                item = dvp_seq_item::type_id::create("item", this);
                item.dvp_data_bytes = new[byte_queue.size()];

                foreach (byte_queue[i]) begin
                    item.dvp_data_bytes[i] = byte_queue[i];
                end

                item.is_start_of_frame = seen_vsync;
                item.v_pulse_cycles    = v_pulse_cnt;
                item.v_blank_cycles    = v_blank_cnt;
                item.h_blank_cycles    = h_blank_cnt;
                
                // 3. STAMP THE CONFIGURATION ONTO THE PACKET
                item.format_cfg = this.cfg_fmt;
                item.res_cfg    = this.cfg_res;

                `uvm_info("DVP_MON", $sformatf("Captured Line: %0d bytes. V_Pulse: %0d clks, V_Blank: %0d clks, H_Blank: %0d clks",item.dvp_data_bytes.size(), item.v_pulse_cycles, item.v_blank_cycles, item.h_blank_cycles), UVM_HIGH)
        
                cam_ap.write(item);

                seen_vsync  = 0;
                v_pulse_cnt = 0;
                v_blank_cnt = 0;
                h_blank_cnt = 0;
            end
        end 
    endtask

endclass : dvp_monitor

`endif // DVP_MONITOR_SV
