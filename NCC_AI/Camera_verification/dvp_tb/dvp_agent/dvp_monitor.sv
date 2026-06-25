`ifndef MONNITOR_SV
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
      `uvm_fatal("DVP_MON", "Virtual interface not found in config_db!")
    end
  endfunction
      
  task run_phase(uvm_phase phase);
    dvp_seq_item item;
    bit [7:0]    byte_queue[$];
    bit          seen_vsync = 0;

    `uvm_info("DVP_MON", "Starting DVP Monitor Run Phase", UVM_LOW)

    forever begin
      // Wait synchronously on the Monitor's clocking block
      @(dvp_vif.cb_mon);

      // Track VSYNC through the clocking block
      if (dvp_vif.cb_mon.dvp_vsync === 1'b1) begin
        seen_vsync = 1'b1;
      end

      // Wait for an active line to start
      if (dvp_vif.cb_mon.dvp_href === 1'b1) begin
        byte_queue.delete(); // Clear the queue from the previous line

        // Sample data as long as HREF remains HIGH
        while (dvp_vif.cb_mon.dvp_href === 1'b1) begin
          byte_queue.push_back(dvp_vif.cb_mon.dvp_data);
          @(dvp_vif.cb_mon); // Advance time using clocking block
        end

        // HREF just dropped LOW. The line is complete!
        item = dvp_seq_item::type_id::create("item", this);
        
        // Dynamically size the item's array to match exactly what we captured
        item.dvp_data_bytes = new[byte_queue.size()];
        
        foreach (byte_queue[i]) begin
          item.dvp_data_bytes[i] = byte_queue[i];
        end

        item.is_start_of_frame = seen_vsync;
        seen_vsync = 0; // Reset for the next line

        `uvm_info("DVP_MON", $sformatf("Sampled 1 Line: %0d bytes. Start of Frame: %0b",item.dvp_data_bytes.size(), item.is_start_of_frame), UVM_HIGH)
        
        // Broadcast the completed line
        cam_ap.write(item);
      end
    end
  endtask

endclass : dvp_monitor

