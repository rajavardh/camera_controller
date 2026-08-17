`ifndef CAMERA_VSEQ_SV
`define CAMERA_VSEQ_SV

class camera_vseq extends uvm_sequence;
    `uvm_object_utils(camera_vseq)
    `uvm_declare_p_sequencer(camera_vsequencer)

    // These are the master knobs. The UVM test will randomize these!
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
        int height;
        int dma_handshakes;
        
        // ------------------------------------------------------------------
        // 1. APB CONFIGURATION (Dynamic Passing)
        // ------------------------------------------------------------------
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        
        // We inject the master knobs into the APB sequence before starting it
        cam_cfg.cfg_fmt = this.vseq_fmt;
        cam_cfg.cfg_res = this.vseq_res;
        
        cam_cfg.start(p_sequencer.apb_seqr); 

        // ------------------------------------------------------------------
        // 2. DVP TRAFFIC GENERATION
        // ------------------------------------------------------------------
        dvp_seq = dvp_sequence::type_id::create("dvp_seq");
        if (!dvp_seq.randomize() with {
            target_res == local::vseq_res; 
            target_fmt == local::vseq_fmt;
        }) begin
            `uvm_error("VSEQ_RAND_ERR", "dvp_seq randomization failed!")
        end

        // ------------------------------------------------------------------
        // 3. DMA HANDSHAKE CALCULATION (From Hardware Spec)
        // ------------------------------------------------------------------
        // First, decode the height dynamically
        if      (this.vseq_res == RES_QVGA)  height = 240;
        else if (this.vseq_res == RES_VGA)   height = 480;
        else if (this.vseq_res == RES_720P)  height = 720;
        else if (this.vseq_res == RES_1080P) height = 1080;

        // Second, adjust for YUV hardware behavior
        if (this.vseq_fmt == FMT_YUV420_I || this.vseq_fmt == FMT_YUV420_P) begin
            // Hardware Spec: YUV triggers DMA interrupt every 2 lines
            dma_handshakes = height / 2;
        end else begin
            // RGB and MJPEG trigger DMA interrupt every 1 line
            dma_handshakes = height;
        end
        
        // ------------------------------------------------------------------
        // 4. PARALLEL EXECUTION (Drive Data & Service DMA Line-by-Line)
        // ------------------------------------------------------------------
        fork
            begin
                dvp_seq.start(p_sequencer.dvp_seqr);
            end

            begin
                // The loop perfectly matches the hardware interrupt count
                for (int i = 0; i < dma_handshakes; i++) begin
                    bit [1:0] active_req_type;

                    // A. Wait for DUT DMA to finish writing the line to the SRAM Buffer
                    dma_sub_seq = dma_base_seq::type_id::create("dma_sub_seq");
                    dma_sub_seq.seq_action = DMA_WAIT_REQ;
                    dma_sub_seq.start(p_sequencer.dma_seqr);
                    active_req_type = dma_sub_seq.dma_req_ack_type;

                    // B. Read the line out of the SRAM immediately
                    axi_read = camera_axi_read_seq::type_id::create("axi_read");
                    
                    // Inject format/resolution so AXI knows how many bursts to send
                    axi_read.cfg_fmt = this.vseq_fmt;
                    axi_read.cfg_res = this.vseq_res;
                    
                    if (!axi_read.randomize() with { 
                        target_addr == local::axi_base_addr; 
                    }) begin
                        `uvm_error("VSEQ_AXI_ERR", "AXI master configuration failed!")
                    end
                    axi_read.start(p_sequencer.axi_rd_seqr);
                    
                    `uvm_info("VSEQ_LINE", $sformatf("Successfully read line index %0d via AXI.", i), UVM_HIGH)

                    // C. Tell the DMA the SRAM is empty and it can drive the next line
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
