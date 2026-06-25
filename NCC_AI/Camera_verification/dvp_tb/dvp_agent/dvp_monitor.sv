`ifndef DVP_MONITOR_SV
`define DVP_MONITOR_SV

class dvp_monitor extends uvm_monitor;

  virtual camera_dvp_if dvp_vif;
  
  uvm_analysis_port #(dvp_seq_item) cam_ap;
  
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
  endfunction
      

  task run_phase(uvm_phase phase);
    dvp_seq_item item;          
    bit [7:0]    byte_queue[$]; // Dynamic temporary queue to capture resolutions
    
    // Hardware delay measurement trackers
    int v_pulse_cnt = 0; 
    int v_blank_cnt = 0;
    int h_blank_cnt = 0;
    bit seen_vsync  = 0;

    `uvm_info("DVP_MON", "Starting DVP Monitor observation loop...", UVM_LOW)

    forever begin
      // Wait synchronously on the Monitor's secure clocking block
      @(dvp_vif.cb_mon);

      // STATE 1: Measure Start-of-Frame (VSYNC Pulse)

      if (dvp_vif.cb_mon.dvp_vsync === 1'b1) begin
        seen_vsync = 1'b1;
        v_pulse_cnt++;
        v_blank_cnt = 0; // Clear blanking trackers for the new frame
        h_blank_cnt = 0;
      end
      
      // STATE 2: Measure Blanking Periods (VSYNC is LOW, HREF is LOW)
      else if (dvp_vif.cb_mon.dvp_href === 1'b0) begin
        if (seen_vsync == 1'b1) begin
          // We saw a VSYNC recently, so this is the Vertical Back Porch delay
          v_blank_cnt++; 
        end else begin
          h_blank_cnt++; 
        end
      end
      
      // STATE 3: Capture Active Video Line (HREF is HIGH)
      // Once HREF goes HIGH, we enter a dedicated while-loop to capture data
      else if (dvp_vif.cb_mon.dvp_href === 1'b1) begin
        byte_queue.delete();// delete old data from the previous line

        // Sample data continuously as long as HREF remains HIGH
        while (dvp_vif.cb_mon.dvp_href === 1'b1) begin
          byte_queue.push_back(dvp_vif.cb_mon.dvp_data);
          @(dvp_vif.cb_mon);
        end

        // Create the sequence item and size its payload array perfectly
        item = dvp_seq_item::type_id::create("item", this);
        item.dvp_data_bytes = new[byte_queue.size()];

        // Pour the raw hardware bytes into the UVM sequence item
        foreach (byte_queue[i]) begin
          item.dvp_data_bytes[i] = byte_queue[i];
        end

        // Attach our precise physical timing measurements
        item.is_start_of_frame = seen_vsync;
        item.v_pulse_cycles    = v_pulse_cnt;
        item.v_blank_cycles    = v_blank_cnt;
        item.h_blank_cycles    = h_blank_cnt;

        `uvm_info("DVP_MON", $sformatf("Captured Line: %0d bytes. V_Pulse: %0d clks, V_Blank: %0d clks, H_Blank: %0d clks",item.dvp_data_bytes.size(), item.v_pulse_cycles, item.v_blank_cycles, item.h_blank_cycles), UVM_HIGH)
        
        // Broadcast the completed line out to the rest of the testbench
        cam_ap.write(item);

        // Reset the timing state machine for the next line
        seen_vsync  = 0;
        v_pulse_cnt = 0;
        v_blank_cnt = 0;
        h_blank_cnt = 0;
      end
    end // end forever loop
  endtask

endclass : dvp_monitor

`endif // DVP_MONITOR_SV
