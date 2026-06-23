`ifndef DVP_SEQ_ITEM_SV
`define DVP_SEQ_ITEM_SV

class dvp_seq_item extends uvm_sequence_item; 

  // 1. The Dynamic Payload 

  rand bit [7:0] dvp_data_bytes[]; 

  // 2. Control Variables 
  rand int pixels_per_line;
  rand int line_count;       // Which line number is this in the frame
  rand bit is_rgb;           // 1 = RGB/MJPEG, 0 = YUV420
  rand bit [2:0] driver_sel; 

  bit is_start_of_frame;     // Tells driver to pulse VSYNC
  rand int h_blank_cycles;   // Tells driver how long to hold HREF low

  `uvm_object_utils_begin(dvp_seq_item)
    `uvm_field_array_int(dvp_data_bytes, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(pixels_per_line, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(line_count, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(is_rgb, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(driver_sel, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(is_start_of_frame, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(h_blank_cycles, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end
    
  function new(string name = "dvp_seq_item");
    super.new(name);
  endfunction

  constraint c_payload_size {
    if (is_rgb == 1) {
      // RGB888 is 3 bytes per pixel
      dvp_data_bytes.size() == (pixels_per_line * 3);
    } else {
      // YUV420 Planar logic will dictate a different size here
      dvp_data_bytes.size() == pixels_per_line; 
    }
  }

  // Realistic horizontal blanking delay
  constraint c_h_blank {
    h_blank_cycles inside {[50:200]};
  }

endclass : dvp_seq_item
`endif
