`ifndef CAMERA_VSEQ_SV
`define CAMERA_VSEQ_SV

class camera_vseq extends uvm_sequence;
    `uvm_object_utils(camera_vseq)
    `uvm_declare_p_sequencer(camera_vsequencer)

    cam_resolution_e vseq_res = RES_QVGA; 
    cam_format_e     vseq_fmt = FMT_RGB888;

    camera_reg_cfg_seq  cam_cfg; 
    dvp_sequence         dvp_seq;
    camera_axi_read_seq  axi_read; 

    function new(string name = "camera_vseq");
        super.new(name);
    endfunction

    virtual task body();
        #100ns;
        `uvm_info("VSEQ", "starting cam register configuration...", UVM_LOW)
        
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        cam_cfg.start(p_sequencer.apb_seqr); 

        #200ns; 

        `uvm_info("VSEQ", "Starting DVP Stream and AXI DMA Monitor...", UVM_LOW)
        
        fork
            // Thread 1: Blast DVP Pixels
            begin
                dvp_seq = dvp_sequence::type_id::create("dvp_seq");
                dvp_seq.target_res = this.vseq_res; 
                dvp_seq.target_fmt = this.vseq_fmt;
                dvp_seq.start(p_sequencer.dvp_seqr);
            end

            // Thread 2: AXI Read Responder
            begin
                forever begin
                    @(posedge p_sequencer.vif_dma.dma_trig_req);
                    
                    axi_read = camera_axi_read_seq::type_id::create("axi_read");
                    
                    if (!axi_read.randomize() with {
                        target_addr  == 32'h0800_0000; // MUST MATCH YOUR DUT MEMORY MAP
                        burst_length == 8'h0F; 
                    }) `uvm_error("VSEQ", "AXI Read Randomization Failed")
                    
                    axi_read.start(p_sequencer.axi_rd_seqr);
                    
                    @(posedge p_sequencer.vif_dma.dma_trig_ack); 
                end
            end
        join_any 

        `uvm_info("VSEQ", "camera Virtual Sequence Complete", UVM_LOW)
    endtask 
endclass

`endif // CAMERA_VSEQ_SV

