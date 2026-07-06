`ifndef CAMERA_VSEQ_SV
`define CAMERA_VSEQ_SV

class camera_vseq extends uvm_sequence;
    `uvm_object_utils(camera_vseq)

    `uvm_declare_p_sequencer(camera_vsequencer)

    cam_resolution_e vseq_res = RES_QVGA; 
    cam_format_e     vseq_fmt = FMT_RGB888;

    camera_reg_base_seq  cam_cfg; 
    dvp_sequence         dvp_seq;

    function new(string name = "camera_vseq");
        super.new(name);
    endfunction

    virtual task body();

        #100ns;
        `uvm_info("VSEQ", "starting cam register configuration block...", UVM_LOW)
        
        cam_cfg = camera_reg_base_seq::type_id::create("cam_cfg");
        cam_cfg.start(p_sequencer.apb_seqr); 

        #200ns; 

        `uvm_info("VSEQ", "Starting DVP  Stream...", UVM_LOW)
        
        dvp_seq = dvp_sequence::type_id::create("dvp_seq");
        
        dvp_seq.target_res = this.vseq_res; 
        dvp_seq.target_fmt = this.vseq_fmt;
        
        dvp_seq.start(p_sequencer.dvp_seqr);

        `uvm_info("VSEQ", "camera Virtual Sequence Complete", UVM_LOW)
    endtask 
endclass

`endif // CAMERA_VSEQ_SV

