`ifndef CAMERA_VSEQ_SV
`define CAMERA_VSEQ_SV

class camera_vseq extends uvm_sequence;
    `uvm_object_utils(camera_vseq)

    `uvm_declare_p_sequencer(camera_vsequencer)

    // Sub-sequence Handles
    camera_reg_cfg_seq  cam_cfg;
    dvp_sequence        dvp_seq;

    function new(string name = "camera_vseq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("VSEQ", "Starting Camera Subsystem Sanity Virtual Sequence", UVM_LOW)

        // =================================================================
        // PHASE 1: APB Register Configuration (RE-ENABLED)
        // =================================================================
        #100ns;
        `uvm_info("VSEQ", "Phase 1: Configuring DUT directly via APB...", UVM_LOW)

        // --- Write 1: Interrupt Mask Reg (Base + 0x1C) -> 0x1F ---
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        if (!cam_cfg.randomize() with {
            target_addr == 32'h0710901C;
            target_data == 32'h0000_001F;
        }) begin
            `uvm_error("VSEQ", "Failed to randomize Interrupt Mask Write")
        end
        cam_cfg.start(p_sequencer.apb_seqr);


        // --- Write 2: DMA Control Reg (Base + 0x24) -> 0x00 ---
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        if (!cam_cfg.randomize() with {
            target_addr == 32'h07109024;
            target_data == 32'h0000_0000;
        }) begin
            `uvm_error("VSEQ", "Failed to randomize DMA Control Write")
        end
        cam_cfg.start(p_sequencer.apb_seqr);


        // --- Write 3: Camera Control Reg (Base + 0x20) -> 0x01 ---
        cam_cfg = camera_reg_cfg_seq::type_id::create("cam_cfg");
        if (!cam_cfg.randomize() with {
            target_addr == 32'h07109020;
            target_data == 32'h0000_0001;
        }) begin
            `uvm_error("VSEQ", "Failed to randomize Camera Control Write")
        end
        cam_cfg.start(p_sequencer.apb_seqr);

        // --- Hardware Settle Time ---
        #200ns; 

        // =================================================================
        // PHASE 2: DVP Video Streaming
        // =================================================================
        `uvm_info("VSEQ", "Phase 2: Starting DVP Video Stream...", UVM_LOW)
        
        dvp_seq = dvp_sequence::type_id::create("dvp_seq");
        // Using QVGA for a faster simulation run
        dvp_seq.target_res = RES_QVGA; 
        dvp_seq.target_fmt = FMT_RGB888;
        
        dvp_seq.start(p_sequencer.dvp_seqr);

        `uvm_info("VSEQ", "Camera Subsystem Sanity Virtual Sequence Complete", UVM_LOW)
    endtask 
endclass

`endif // CAMERA_VSEQ_SV
