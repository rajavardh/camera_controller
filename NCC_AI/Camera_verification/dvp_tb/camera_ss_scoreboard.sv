`ifndef CAMERA_SS_SCOREBOARD_SV
`define CAMERA_SS_SCOREBOARD_SV

`uvm_analysis_imp_decl(_dvp)
`uvm_analysis_imp_decl(_axi)

class camera_ss_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(camera_ss_scoreboard)

    uvm_analysis_imp_dvp #(dvp_seq_item, camera_ss_scoreboard)   dvp_export;
    uvm_analysis_imp_axi #(axi4_master_tx, camera_ss_scoreboard) axi_rd_export;

    cam_format_e cfg_fmt;
    int width;
    
    // --- DYNAMIC PADDING QUEUES ---
    int valid_bytes_q[$];
    int stride_q[$];
    
    int active_valid_bytes;
    int active_stride;
    int axi_byte_count_this_line;
    
    // YUV Accumulator & Planar Sorters
    int yuv_byte_accumulator;
    bit yuv_line_toggle;
    bit [7:0] planar_y_q[$];
    bit [7:0] planar_u_q[$];
    bit [7:0] planar_v_q[$];
    // --------------------------------

    bit is_configured; 
    bit [7:0] expected_pixel_q[$];
    bit [7:0] actual_pixel_q[$];

    int expected_count;
    int actual_count;
    int match_count;
    int mismatch_count;

    function new(string name = "camera_ss_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        match_count              = 0;
        mismatch_count           = 0;
        expected_count           = 0;
        actual_count             = 0;
        axi_byte_count_this_line = 0;
        active_stride            = 0;
        yuv_byte_accumulator     = 0;
        yuv_line_toggle          = 0;
        is_configured            = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        dvp_export    = new("dvp_export", this);
        axi_rd_export = new("axi_rd_export", this);
    endfunction

    virtual function void write_dvp(dvp_seq_item item);
        int current_valid_bytes;
        int max_line_bytes;
        int hardware_stride;
        
        if (is_configured == 0) begin
            this.cfg_fmt = item.format_cfg;
            case (item.res_cfg)
                RES_720P:  this.width = 1280;
                RES_1080P: this.width = 1920;
                RES_VGA:   this.width = 640;
                RES_QVGA:  this.width = 320;
                default:   this.width = 320;
            endcase
            
            `uvm_info("SCB_CFG", $sformatf("Scoreboard Auto-Configured: Format=%s, Width=%0d", 
                                           cfg_fmt.name(), width), UVM_LOW)
            is_configured = 1;
        end

        if (cfg_fmt == FMT_MJPEG) begin
            current_valid_bytes = item.dvp_data_bytes.size() - 2; 
        end else begin
            current_valid_bytes = item.dvp_data_bytes.size();
        end
        
        max_line_bytes  = width * 3;
        hardware_stride = ((max_line_bytes + 127) / 128) * 128;

        // 3. FORMAT SPECIFIC PROCESSING
        if (cfg_fmt == FMT_YUV420_P) begin
            
            if (yuv_line_toggle == 0) begin
                // Line 0 (YYYY): Direct to Y Queue
                for (int i = 0; i < item.dvp_data_bytes.size(); i++) begin
                    planar_y_q.push_back(item.dvp_data_bytes[i]);
                end
                yuv_line_toggle = 1;
                
            end else begin
                // Line 1 (YUYV): Unzip exactly like the RTL accumulators
                for (int i = 0; i < item.dvp_data_bytes.size(); i += 4) begin
                    planar_y_q.push_back(item.dvp_data_bytes[i]);     // Y0
                    planar_u_q.push_back(item.dvp_data_bytes[i+1]);   // U0
                    planar_y_q.push_back(item.dvp_data_bytes[i+2]);   // Y1
                    planar_v_q.push_back(item.dvp_data_bytes[i+3]);   // V0
                end
                
                // Flush to master queue in RTL Memory Order (Y block, U block, V block)
                while (planar_y_q.size() > 0) begin expected_pixel_q.push_back(planar_y_q.pop_front()); expected_count++; end
                while (planar_u_q.size() > 0) begin expected_pixel_q.push_back(planar_u_q.pop_front()); expected_count++; end
                while (planar_v_q.size() > 0) begin expected_pixel_q.push_back(planar_v_q.pop_front()); expected_count++; end
                
                // PUSH 3 SEPARATE PADDING BOUNDARIES TO MATCH THE 3 AXI READS!
                valid_bytes_q.push_back(width * 2);
                stride_q.push_back((((width * 2) + 127) / 128) * 128); // Y Stride
                
                valid_bytes_q.push_back(width / 2);
                stride_q.push_back((((width / 2) + 127) / 128) * 128); // U Stride
                
                valid_bytes_q.push_back(width / 2);
                stride_q.push_back((((width / 2) + 127) / 128) * 128); // V Stride
                
                yuv_line_toggle = 0;
            end
            
        end else if (cfg_fmt == FMT_YUV420_I) begin
            yuv_byte_accumulator += current_valid_bytes;
            for (int i = 0; i < item.dvp_data_bytes.size(); i++) begin
                expected_pixel_q.push_back(item.dvp_data_bytes[i]);
                expected_count++;
            end
            
            if (yuv_line_toggle == 1) begin
                valid_bytes_q.push_back(yuv_byte_accumulator);
                stride_q.push_back(hardware_stride); 
                yuv_byte_accumulator = 0;
            end
            yuv_line_toggle = ~yuv_line_toggle;
            
        end else begin
            valid_bytes_q.push_back(current_valid_bytes);
            stride_q.push_back(hardware_stride);
            for (int i = 0; i < item.dvp_data_bytes.size(); i++) begin
                if (cfg_fmt == FMT_MJPEG && i < 2) continue; 
                expected_pixel_q.push_back(item.dvp_data_bytes[i]);
                expected_count++;
            end
        end
    endfunction

    virtual function void write_axi(axi4_master_tx txn);
        int num_beats = txn.arlen + 1;
        int valid_bytes_per_beat = 16; 
        
        for (int beat = 0; beat < num_beats; beat++) begin
            for (int byte_idx = 0; byte_idx < valid_bytes_per_beat; byte_idx++) begin
                if (axi_byte_count_this_line == 0) begin
                    if (valid_bytes_q.size() > 0) begin
                        active_valid_bytes = valid_bytes_q.pop_front();
                        active_stride      = stride_q.pop_front();
                    end
                end
                
                if (axi_byte_count_this_line < active_valid_bytes) begin
                    actual_pixel_q.push_back(txn.rdata[beat][(byte_idx * 8) +: 8]);
                    actual_count++;
                end
                
                axi_byte_count_this_line++;
                if (axi_byte_count_this_line == active_stride) begin
                    axi_byte_count_this_line = 0;
                end
            end
        end
    endfunction

    task run_phase(uvm_phase phase);
        bit [7:0] exp_p;
        bit [7:0] act_p;
        super.run_phase(phase);
        forever begin
            wait(expected_count > 0 && actual_count > 0);
            exp_p = expected_pixel_q.pop_front();
            act_p = actual_pixel_q.pop_front();
            expected_count--;
            actual_count--;

            if (exp_p === act_p) begin
                match_count++;
                `uvm_info("SCB_BYTE_MATCH", $sformatf("Data Match (Byte %0d): Expected = %02h | AXI Read = %02h", match_count, exp_p, act_p), UVM_NONE)
                if (match_count % 10000 == 0) begin
                    `uvm_info("SCB_MATCH", $sformatf("Verified %0d valid bytes perfectly...", match_count), UVM_NONE)
                end
            end else begin
                `uvm_error("SCB_MISMATCH", $sformatf("CORRUPTION at valid byte %0d! Expected: %02h | AXI Read: %02h", match_count, exp_p, act_p))
                mismatch_count++;
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_REPORT", "===============================================", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Total Valid Bytes Verified : %0d", match_count), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Total Data Corruptions     : %0d", mismatch_count), UVM_NONE)
        `uvm_info("SCB_REPORT", "===============================================", UVM_NONE)
    endfunction
endclass : camera_ss_scoreboard
`endif // CAMERA_SS_SCOREBOARD_SV
