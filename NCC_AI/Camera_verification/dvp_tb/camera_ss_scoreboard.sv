`ifndef CAMERA_SS_SCOREBOARD_SV
`define CAMERA_SS_SCOREBOARD_SV

`uvm_analysis_imp_decl(_dvp)
`uvm_analysis_imp_decl(_axi)

class camera_ss_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(camera_ss_scoreboard)

    uvm_analysis_imp_dvp #(dvp_seq_item, camera_ss_scoreboard)   dvp_export;
    uvm_analysis_imp_axi #(axi4_master_tx, camera_ss_scoreboard) axi_rd_export;

    bit [7:0] expected_pixel_q[$];
    bit [7:0] actual_pixel_q[$];

    int expected_count;
    int actual_count;

    int match_count;
    int mismatch_count;

    function new(string name = "camera_ss_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        match_count        = 0;
        mismatch_count     = 0;
        expected_count     = 0;
        actual_count       = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        dvp_export    = new("dvp_export", this);
        axi_rd_export = new("axi_rd_export", this);
    endfunction

    virtual function void write_dvp(dvp_seq_item item);
        foreach (item.dvp_data_bytes[i]) begin
            expected_pixel_q.push_back(item.dvp_data_bytes[i]);
            expected_count++;
        end
        `uvm_info("SCB_DVP", $sformatf("Captured DVP Line %0d. Total Expected: %0d", 
                                       item.line_id, expected_pixel_q.size()), UVM_NONE)
    endfunction

    virtual function void write_axi(axi4_master_tx txn);
        // THE FIX: Safely unpack the entire 60-beat burst array
        int num_beats = txn.arlen + 1;
        int valid_bytes_per_beat = 16; // Based on AXI arsize == READ_16_BYTES
        
        for (int beat = 0; beat < num_beats; beat++) begin
            for (int byte_idx = 0; byte_idx < valid_bytes_per_beat; byte_idx++) begin
                actual_pixel_q.push_back(txn.rdata[beat][(byte_idx * 8) +: 8]);
                actual_count++;
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
                
                if (match_count % 960 == 0) begin
                    `uvm_info("SCB_MATCH", $sformatf("Line %0d Verified! %0d consecutive pixels matched perfectly.", 
                                                      (match_count/960)-1, match_count), UVM_NONE)
                end
                
            end else begin
                // THIS will print the shift (Expected 01 -> AXI Read 10)
                `uvm_error("SCB_MISMATCH", $sformatf("CORRUPTION! Expected: %02h | AXI Read: %02h", exp_p, act_p))
                mismatch_count++;
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_REPORT", "===============================================", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Total Pixels Verified  : %0d", match_count), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Total Data Corruptions : %0d", mismatch_count), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Unmatched Expected Pix : %0d", expected_pixel_q.size()), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Unmatched Actual Pix   : %0d", actual_pixel_q.size()), UVM_NONE)
        `uvm_info("SCB_REPORT", "===============================================", UVM_NONE)
    endfunction

endclass : camera_ss_scoreboard

`endif // CAMERA_SS_SCOREBOARD_SV
