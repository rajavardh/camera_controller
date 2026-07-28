`ifndef CAMERA_VSEQ
`define CAMERA_VSEQ

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

        dma_base_seq dma_sub_seq;
        
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        cam_cfg.start(p_sequencer.apb_seqr); 

        dvp_frame_stream_done = 1'b0;

        dma_base_sequence dma_sub_seq;
        int num_lines;

        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        cam_cfg.start(p_sequencer.apb_seqr); 

        // 1. Calculate exactly how many lines to read so the thread can exit safely
        if (vseq_res == RES_QVGA) num_lines = 240;
        else                      num_lines = 480; 

        
        fork
            // Thread 1: Drive the DVP pixels
            begin
                dvp_seq = dvp_sequence::type_id::create("dvp_seq");
                dvp_seq.target_res = this.vseq_res; 
                dvp_seq.target_fmt = this.vseq_fmt;
                dvp_seq.start(p_sequencer.dvp_seqr);

                dvp_frame_stream_done = 1'b1;


            end

            // Thread 2: Acknowledge DMA and Fetch AXI data
            begin

                while (!dvp_frame_stream_done) begin
                    dma_sub_seq = dma_base_seq::type_id::create("dma_sub_seq");
                    
                    dma_sub_seq.start(p_sequencer.dma_seqr);
                    
                    `uvm_info("VSEQ", $sformatf("Handshake success. Request Type: %0b", dma_sub_seq.rx_req_type), UVM_HIGH)

                for (int i = 0; i < num_lines; i++) begin
                    
                    dma_sub_seq = dma_base_sequence::type_id::create("dma_sub_seq");
                    dma_sub_seq.start(p_sequencer.dma_seqr);
                    
                    `uvm_info("VSEQ", $sformatf("Line %0d DMA Handshake success. Request Type: %0b", i, dma_sub_seq.dma_req_ack_type), UVM_HIGH)

                    
                    axi_read = camera_axi_read_seq::type_id::create("axi_read");
                    
                    if (!axi_read.randomize() with {

                        target_addr  == 14'h0000; 
                        burst_length == 8'h0F;    

                        // 3. Drive the full 32-bit base address to the AXI VIP
                        target_addr  == 32'h0800_0000; 

                    }) begin
                        `uvm_error("VSEQ_AXI_ERR", "AXI VIP Randomization Parameters Failed!")
                    end
                    

                    axi_read.start(p_sequencer.axi_vip_master_seqr);
                end
            end
        join
        `uvm_info("VSEQ_DONE", "Virtual Sequence Completed .", UVM_LOW)
    endtask 
endclass
`endif 











