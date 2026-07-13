`ifndef CAMERA_REG_CFG_SEQ_SV
`define CAMERA_REG_CFG_SEQ_SV

class camera_reg_cfg_seq extends apb_master_base_seq; // (or your specific APB base sequence)
    `uvm_object_utils(camera_reg_cfg_seq)
    bit[31:0] read_data;
    
    function new(string name = "camera_reg_cfg_seq");
        super.new(name);
    endfunction

    virtual task body();
        super.body();
    
        `uvm_info("REG_BASE", "Inside camera base register seq: Camera Enable & Generic Configurations...", UVM_LOW)
        
        write_reg(32'h0710901C, 32'h0000_0000); //  Interrupt Mask Reg
        write_reg(32'h07109024, 32'h0000_0000); //  DMA Control Reg
        write_reg(32'h07109020, 32'h0000_0001); //  Camera Enable / Control
        read_reg(32'h07109020,read_data ); //  Camera Enable / Control
        $display($time,"************************* read_cam_en:%0h ***************************",read_data);  //TODO DEL
    endtask


    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        apb_master_tx write_tx = apb_master_tx::type_id::create("write_tx");
        
        start_item(write_tx);
        write_tx.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
        
        if (!write_tx.randomize() with {
            pwrite        == apb_global_pkg::WRITE;   
            pselx         == apb_global_pkg::SLAVE_0; 
            transfer_size == apb_global_pkg::BIT_32;  
        }) begin
            `uvm_error("APB_SEQ", "Failed to randomize APB write transaction rules")
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
            pwrite        == apb_global_pkg::READ;    
            pselx         == apb_global_pkg::SLAVE_0; 
            transfer_size == apb_global_pkg::BIT_32;  
        }) begin
            `uvm_error("APB_SEQ", "Failed to randomize APB read transaction rules")
        end
        
        read_tx.paddr = addr;
        finish_item(read_tx);
        
        data = read_tx.prdata;
    endtask


endclass

`endif // CAMERA_REG_CFG_SEQ_SV
