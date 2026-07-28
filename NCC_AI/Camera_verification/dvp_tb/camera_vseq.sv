`ifndef CAMERA_VSEQ_SV
`define CAMERA_VSEQ_SV

class camera_vseq extends uvm_sequence;
    `uvm_object_utils(camera_vseq)
    `uvm_declare_p_sequencer(camera_vsequencer)

    cam_resolution_e vseq_res = RES_QVGA; 
    cam_format_e     vseq_fmt = FMT_RGB888;

    camera_reg_cfg_seq   cam_cfg; 
    dvp_sequence         dvp_seq;
    camera_axi_read_seq  axi_read; 

    function new(string name = "camera_vseq");
        super.new(name);
    endfunction

    virtual task body();
        dma_base_sequence dma_sub_seq;
        int num_lines;
        bit [31:0] ping_pong_addr; // Tracks the memory bank
        
        // 1. Configure the APB Registers
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        cam_cfg.start(p_sequencer.apb_seqr); 

        // 2. Set mechanical loop based on resolution
        if (vseq_res == RES_QVGA) num_lines = 240;
        else                      num_lines = 480; 
        
        fork
            // Thread 1: Drive the DVP pixels
            begin
                dvp_seq = dvp_sequence::type_id::create("dvp_seq");
                dvp_seq.target_res = this.vseq_res; 
                dvp_seq.target_fmt = this.vseq_fmt;
                dvp_seq.start(p_sequencer.dvp_seqr);
            end

            // Thread 2: Acknowledge DMA and Fetch AXI data
            begin
                for (int i = 0; i < num_lines; i++) begin
                    dma_sub_seq = dma_base_sequence::type_id::create("dma_sub_seq");
                    dma_sub_seq.start(p_sequencer.dma_seqr);
                    
                    `uvm_info("VSEQ", $sformatf("Line %0d DMA Handshake success. Request Type: %0b", i, dma_sub_seq.dma_req_ack_type), UVM_HIGH)
                    
                    axi_read = camera_axi_read_seq::type_id::create("axi_read");
                    
                    // Toggle between Ping (0x0000) and Pong (0x1000) buffers
                    if (i % 2 == 0) ping_pong_addr = 32'h0800_0000;
                    else            ping_pong_addr = 32'h0800_1000;

                    // Pass the toggled 32-bit address down to the AXI sequence
                    if (!axi_read.randomize() with {
                        target_addr  == ping_pong_addr; 
                    }) begin
                        `uvm_error("VSEQ_AXI_ERR", "AXI VIP Randomization Parameters Failed!")
                    end
                    
                    // Ensure the sequencer name matches your environment
                    axi_read.start(p_sequencer.axi_rd_seqr);
                end
            end
        join
        
        `uvm_info("VSEQ_DONE", "Virtual Sequence Completed Successfully.", UVM_LOW)
    endtask 
endclass
`endif // CAMERA_VSEQ_SV
