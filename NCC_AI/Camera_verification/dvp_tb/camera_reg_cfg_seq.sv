`ifndef CAMERA_REG_CFG_SEQ_SV
`define CAMERA_REG_CFG_SEQ_SV

class camera_reg_cfg_seq extends uvm_sequence; // (or your specific APB base sequence)
    `uvm_object_utils(camera_reg_cfg_seq)
    `uvm_declare_p_sequencer(apb_master_sequencer)

    function new(string name = "camera_reg_cfg_seq");
        super.new(name);
    endfunction

    // ========================================================================
    // Custom API Tasks (NAMESPACE COLLISION FIXED)
    // ========================================================================

    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        apb_master_tx write_tx = apb_master_tx::type_id::create("write_tx");
        
        start_item(write_tx);
        write_tx.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
        
        if (!write_tx.randomize() with {
            pwrite        == apb_global_pkg::WRITE;   // <--- Scoped
            pselx         == apb_global_pkg::SLAVE_0; // <--- Scoped
            transfer_size == apb_global_pkg::BIT_32;  // <--- Scoped
        }) begin
            `uvm_error("APB_API", "Failed to randomize APB write transaction rules")
        end
        
        write_tx.paddr  = addr;
        write_tx.pwdata = data;
        
        finish_item(write_tx);
    endtask

    virtual task read_reg(bit [31:0] addr, output bit [31:0] data);
        apb_master_tx read_tx = apb_master_tx::type_id::create("read_tx");
        
        start_item(read_tx);
        read_tx.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
        
        if (!read_tx.randomize() with {
            pwrite        == apb_global_pkg::READ;    // <--- Scoped
            pselx         == apb_global_pkg::SLAVE_0; // <--- Scoped
            transfer_size == apb_global_pkg::BIT_32;  // <--- Scoped
        }) begin
            `uvm_error("APB_API", "Failed to randomize APB read transaction rules")
        end
        
        read_tx.paddr = addr;
        finish_item(read_tx);
        
        data = read_tx.prdata;
    endtask

    // ... (Keep your virtual task body() here) ...

endclass

`endif // CAMERA_REG_CFG_SEQ_SV
