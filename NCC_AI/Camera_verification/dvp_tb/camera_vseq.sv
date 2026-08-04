`ifndef CAMERA_VSEQ_SV
`define CAMERA_VSEQ_SV

class camera_vseq extends uvm_sequence;
    `uvm_object_utils(camera_vseq)
    `uvm_declare_p_sequencer(camera_vsequencer)

    rand cam_resolution_e vseq_res; 
    rand cam_format_e     vseq_fmt;
    rand bit [31:0]       axi_base_addr;

    camera_reg_cfg_seq   cam_cfg; 
    dvp_sequence         dvp_seq;
    camera_axi_read_seq  axi_read; 
    
    function new(string name = "camera_vseq");
        super.new(name);
    endfunction

    virtual task body();
        dma_base_seq dma_sub_seq; 
        int num_lines;
        
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        cam_cfg.start(p_sequencer.apb_seqr); 

        dvp_seq = dvp_sequence::type_id::create("dvp_seq");
        if (!dvp_seq.randomize() with {
            target_res == local::vseq_res; 
            target_fmt == local::vseq_fmt;
        }) begin
            `uvm_error("VSEQ_RAND_ERR", "dvp_seq randomization failed!")
        end

        num_lines = (this.vseq_res == RES_QVGA) ? 240 : 480; 
        
	fork
            begin
                dvp_seq.start(p_sequencer.dvp_seqr);
            end

            begin
                for (int i = 0; i < num_lines; i++) begin
                    bit [1:0] active_req_type;

                    dma_sub_seq = dma_base_seq::type_id::create("dma_sub_seq");
                    dma_sub_seq.seq_action = DMA_WAIT_REQ;
                    dma_sub_seq.start(p_sequencer.dma_seqr);
                    active_req_type = dma_sub_seq.dma_req_ack_type;

                    axi_read = camera_axi_read_seq::type_id::create("axi_read");
                    if (!axi_read.randomize() with { 
                        target_addr == local::axi_base_addr; 
                    }) begin
                        `uvm_error("VSEQ_AXI_ERR", "AXI master configuration failed!")
                    end
                    axi_read.start(p_sequencer.axi_rd_seqr);
                    
                    `uvm_info("VSEQ_LINE", $sformatf("Successfully read line index %0d via AXI.", i), UVM_HIGH)

                    dma_sub_seq = dma_base_seq::type_id::create("dma_sub_seq");
                    dma_sub_seq.seq_action   = DMA_DRIVE_ACK;
                    dma_sub_seq.seq_ack_type = active_req_type;
                    dma_sub_seq.start(p_sequencer.dma_seqr);
                end
            end
        join
        
        `uvm_info("VSEQ_COMPLETE", "Simulation virtual frame processing sequence completed perfectly.", UVM_LOW)
    endtask 
endclass

`endif // CAMERA_VSEQ_SV

