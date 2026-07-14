`ifndef CAMERA_VSEQ_SV
`define CAMERA_VSEQ_SV

class camera_vseq extends uvm_sequence;
    `uvm_object_utils(camera_vseq)
    `uvm_declare_p_sequencer(camera_vsequencer)

    cam_resolution_e vseq_res = RES_QVGA; 
    cam_format_e     vseq_fmt = FMT_RGB888;

    bit [31:0] ping_buffer_addr = 32'h0800_0000; 
    bit [31:0] pong_buffer_addr = 32'h0800_2000; 

    camera_reg_cfg_seq   cam_cfg; 
    dvp_sequence         dvp_seq;
    camera_axi_read_seq  axi_read; 

    bit dvp_frame_stream_done = 1'b0;

    function new(string name = "camera_vseq");
        super.new(name);
    endfunction

    virtual task body();
        bit [1:0]  sampled_trig_type;
        int        line_counter = 0;
        bit [31:0] target_axi_addr;
        
        if (p_sequencer.vif_dma == null) begin
            `uvm_fatal("VSEQ_ERR", "Virtual DMA interface pointer (vif_dma) is null on the virtual sequencer!")
        end

        #100ns;
        `uvm_info("VSEQ", "Starting camera register configuration over APB...", UVM_LOW)
        
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        cam_cfg.start(p_sequencer.apb_seqr); 

        p_sequencer.vif_dma.dma_trig_ack      = 1'b0;
        p_sequencer.vif_dma.dma_trig_ack_type = 2'b00;

        #200ns; 
        
        dvp_frame_stream_done = 1'b0;
        line_counter          = 0;
        
        fork
            begin
                dvp_seq = dvp_sequence::type_id::create("dvp_seq");
                dvp_seq.target_res = this.vseq_res; 
                dvp_seq.target_fmt = this.vseq_fmt;
                dvp_seq.start(p_sequencer.dvp_seqr);
                
                dvp_frame_stream_done = 1'b1;
                `uvm_info("VSEQ", "DVP sequence finished transmitting lines.", UVM_LOW)
            end

            begin
               while (!dvp_frame_stream_done || p_sequencer.vif_dma.dma_trig_req === 1'b1) begin
                    
                    `uvm_info("WAIT_REQ", "waiting for dma request.....", UVM_MEDIUM)
                    p_sequencer.vif_dma.monitor_dma_req(sampled_trig_type);
                    `uvm_info("DRV_ACK", " Received dma request. Driving DMA ACK to DUT", UVM_MEDIUM)
                    
                    `uvm_info("REQ_ACK_TYP", $sformatf("DMA Trigger/request Type: 2'b%0b", sampled_trig_type), UVM_MEDIUM)
                    
                    p_sequencer.vif_dma.drive_dma_ack(sampled_trig_type); 
                    
                    `uvm_info("REQ_ACK_TYP", $sformatf("pixel line count %0d", line_counter), UVM_MEDIUM)
                    
                    target_axi_addr = (line_counter % 2 == 0) ? ping_buffer_addr : pong_buffer_addr;
                    
                    axi_read = camera_axi_read_seq::type_id::create("axi_read");
                    
                    if (!axi_read.randomize() with {
                        target_addr  == local::target_axi_addr;
                        burst_length == 8'h0F; // 16 beats per single line transfer 
                    }) begin
                        `uvm_error("VSEQ_AXI", "AXI Read Randomization Parameters Failed!")
                    end
                    
                    `uvm_info("AXI_RD_SEQ", "AXI read triggered", UVM_MEDIUM)
                    axi_read.start(p_sequencer.axi_rd_seqr);
                    `uvm_info("AXI_RD_SEQ", "AXI read completed", UVM_MEDIUM)
                    
                    line_counter++;
                end
            end
        join

        `uvm_info("VSEQ", "camera Virtual Sequence Complete", UVM_LOW)
    endtask 
endclass

`endif // CAMERA_VSEQ_SV
