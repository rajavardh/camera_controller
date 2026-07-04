`ifndef CAMERA_REG_CFG_SEQ_SV
`define CAMERA_REG_CFG_SEQ_SV

class camera_reg_cfg_seq extends uvm_sequence #(apb_master_tx);
    `uvm_object_utils(camera_reg_cfg_seq)

    // 1. Tell UVM this sequence explicitly runs on the APB sequencer
    `uvm_declare_p_sequencer(apb_master_sequencer)

    // The explicit targets you want to write to the DUT
    rand bit [31:0] target_addr;
    rand bit [31:0] target_data;

    function new(string name="camera_reg_cfg_seq");
        super.new(name);
    endfunction

    virtual task body();
        req = apb_master_tx::type_id::create("req");
        
        // 2. Grab the config natively from the physical sequencer!
        req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
        
        start_item(req);
        
        // 3. Let the VIP handle the protocol control signals
        if (!req.randomize() with {
            pwrite        == WRITE;
            pselx         == SLAVE_0;
            transfer_size == BIT_32;
        }) begin
            `uvm_error("APB_SEQ", "Failed to randomize APB protocol control signals")
        end
        
        // 4. The Override: Overwrite whatever random garbage the VIP put in the address/data
        req.paddr  = target_addr;
        req.pwdata = target_data;
        
        // 5. Send the exact transaction to the driver
        finish_item(req);
    endtask
endclass

`endif // CAMERA_REG_CFG_SEQ_SV
