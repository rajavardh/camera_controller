`ifndef DVP_SEQ_ITEM_SV
`define DVP_SEQ_ITEM_SV

// Hardware Configuration Enums 
typedef enum bit [1:0] {
  FMT_RGB888   = 2'b00, 
  FMT_MJPEG    = 2'b01, 
  FMT_YUV420_I = 2'b10, // Interleaved
  FMT_YUV420_P = 2'b11  // Planar
} cam_format_e;

typedef enum bit [1:0] {
  RES_720P  = 2'b00, 
  RES_1080P = 2'b01, 
  RES_VGA   = 2'b10, 
  RES_QVGA  = 2'b11
} cam_resolution_e;

class dvp_seq_item extends uvm_sequence_item; 

  // 1. The Dynamic Payload
  rand bit [7:0] dvp_data_bytes[]; 

  // 2. Hardware Configuration Variables
  rand cam_format_e     format_cfg;
  rand cam_resolution_e res_cfg;
  
  // 3. Derived Variables (Must be rand for the solver to size the array)
  rand int pixels_per_line;
  rand int line_count;       
  
  // State variable: MUST be set by the sequence BEFORE calling randomize()
  int line_id;               
  
  rand bit [2:0] driver_sel; 

  // 4. Timing Metadata
  rand bit     is_start_of_frame;
  rand bit     is_end_of_frame;    
  rand int h_blank_cycles;     
  rand int v_pulse_cycles;     
  rand int v_blank_cycles;     

  `uvm_object_utils_begin(dvp_seq_item)
    `uvm_field_array_int(dvp_data_bytes, UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(cam_format_e, format_cfg, UVM_ALL_ON)
    `uvm_field_enum(cam_resolution_e, res_cfg, UVM_ALL_ON)
    `uvm_field_int(pixels_per_line, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(line_count, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(line_id, UVM_ALL_ON | UVM_DEC) 
    `uvm_field_int(driver_sel, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(is_start_of_frame, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(is_end_of_frame, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(h_blank_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(v_pulse_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(v_blank_cycles, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end
    
  function new(string name = "dvp_seq_item");
    super.new(name);
  endfunction
  
  // 1. Map Resolution Enum to actual physical width
  constraint c_resolution_mapping {
    if (res_cfg == RES_720P)  { pixels_per_line == 1280; line_count == 720;  }
    if (res_cfg == RES_1080P) { pixels_per_line == 1920; line_count == 1080; }
    if (res_cfg == RES_VGA)   { pixels_per_line == 640;  line_count == 480;  }
    if (res_cfg == RES_QVGA)  { pixels_per_line == 320;  line_count == 240;  }
  }

  // 2. Map Format Enum to Physical Array Size 
  constraint c_payload_size {
    
    // RGB888: Always 3 bytes per pixel
    if (format_cfg == FMT_RGB888) {
      dvp_data_bytes.size() == (pixels_per_line * 3);
    } 
    
    // YUV420 (Interleaved AND Planar): Alternating line widths over the physical DVP pins
    else if (format_cfg == FMT_YUV420_I || format_cfg == FMT_YUV420_P) {
      if (line_id % 2 == 0) {
        dvp_data_bytes.size() == (pixels_per_line * 2); // Even lines: YUYV (2 bytes/pix)
      } else {
        dvp_data_bytes.size() == pixels_per_line;       // Odd lines: YYYY (1 byte/pix)
      }
    } 
    
    // MJPEG: Fixed DVP line buffer width (padded with 0xFF later)
    else if (format_cfg == FMT_MJPEG) {
      dvp_data_bytes.size() == (pixels_per_line * 2); 
    }
  }

  // 3. Timing Constraints
  constraint c_timing {
    h_blank_cycles inside {[50:200]};
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
