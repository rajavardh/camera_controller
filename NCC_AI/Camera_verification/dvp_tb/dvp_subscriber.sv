`ifndef DVP_SUBSCRIBER_SV
`define DVP_SUBSCRIBER_SV

class dvp_subscriber extends uvm_component;

  uvm_analysis_imp #(dvp_seq_item, dvp_subscriber) cam_export;

  `uvm_component_utils(dvp_subscriber)

  // 1. Variables to hold the sampled data
  cam_format_e     cov_fmt;
  cam_resolution_e cov_res;

  // ============================================================================
  // COVERGROUP DEFINITION
  // ============================================================================
  covergroup cam_cfg_cg;
    option.per_instance = 1;
    option.name = "Camera Format and Resolution Coverage";

    // Coverpoint for all Formats
    cp_format: coverpoint cov_fmt {
      bins rgb        = {FMT_RGB888};
      bins mjpeg      = {FMT_MJPEG};
      bins yuv_int    = {FMT_YUV420_I};
      bins yuv_planar = {FMT_YUV420_P};
    }

    // Coverpoint for all Resolutions
    cp_resolution: coverpoint cov_res {
      bins res_720p  = {RES_720P};
      bins res_1080p = {RES_1080P};
      bins res_vga   = {RES_VGA};
      bins res_qvga  = {RES_QVGA};
    }

    // Cross Coverage: Prove every format ran at every resolution
    cross_fmt_res: cross cp_format, cp_resolution;
  endgroup

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================
  function new(string name = "dvp_subscriber", uvm_component parent = null);
    super.new(name, parent);
    cam_export = new("cam_export", this);
    cam_cfg_cg = new(); 
  endfunction

  // ============================================================================
  // THE WRITE FUNCTION (Triggered by Monitor via cam_export)
  // ============================================================================
  virtual function void write(dvp_seq_item item);

    `uvm_info("DVP_SUB", $sformatf("SUCCESS! Subscriber received Line %0d for coverage.", item.line_id), UVM_HIGH)
    
    // 3. Logic: Only sample once per frame (on the first line) to save CPU time
    if (item.is_start_of_frame == 1'b1) begin
        cov_fmt = item.format_cfg;
        cov_res = item.res_cfg;
        
        // Trigger the covergroup to record these values into the database
        cam_cfg_cg.sample();
        
        `uvm_info("[DVP_COV]", $sformatf("Coverage Sampled -> Format: %s | Resolution: %s", cov_fmt.name(), cov_res.name()), UVM_LOW)
    end
  endfunction

endclass : dvp_subscriber

`endif // DVP_SUBSCRIBER_SV
