`ifndef DVP_SEQ_ITEM_SV
`define DVP_SEQ_ITEM_SV

// formats 
typedef enum bit [1:0] {
  RGB888 = 2'b00, 
  RGB565 = 2'b01, 
  YUV422 = 2'b10, 
  RAW8   = 2'b11  
} video_format_e;

class dvp_seq_item extends uvm_sequence_item; 

  // 1. The Dynamic Payload
  rand bit [7:0] dvp_data_bytes[]; 

  // 2. Control Variables (Upgraded to Enum!)
  rand int            pixels_per_line;
  rand int            line_count;       
  rand video_format_e vid_format;      
  rand bit [2:0]      driver_sel; 

  // 3. Timing Metadata
  bit      is_start_of_frame;  
  rand int h_blank_cycles;     
  rand int v_pulse_cycles;     
  rand int v_blank_cycles;     

  `uvm_object_utils_begin(dvp_seq_item)
    `uvm_field_array_int(dvp_data_bytes, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(pixels_per_line, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(line_count, UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(video_format_e, vid_format, UVM_ALL_ON)
    `uvm_field_int(driver_sel, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(is_start_of_frame, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(h_blank_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(v_pulse_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(v_blank_cycles, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end
    
  function new(string name = "dvp_seq_item");
    super.new(name);
  endfunction
  
  // Dynamically calculate payload size based on the specific format
  constraint c_payload_size {
    if (vid_format == RGB888) {
      dvp_data_bytes.size() == (pixels_per_line * 3);
    } 
    else if (vid_format == RGB565 || vid_format == YUV422) {
      dvp_data_bytes.size() == (pixels_per_line * 2);
    } 
    else { // RAW8
      dvp_data_bytes.size() == pixels_per_line; 
    }
  }

  // Horizontal Blanking 
  constraint c_h_blank {
    h_blank_cycles inside {[50:200]};
  }

  // Vertical Timing 
  constraint c_v_timing {
    if (is_start_of_frame == 1) {
      v_pulse_cycles inside {[3:10]};    
      v_blank_cycles inside {[100:500]}; 
    } else {
      v_pulse_cycles == 0;
      v_blank_cycles == 0;
    }
  }

endclass : dvp_seq_item
`endif // DVP_SEQ_ITEM_SV
