`ifndef CAMERA_AXI_READ_SEQ_SV
`define CAMERA_AXI_READ_SEQ_SV

// Bypassing the VIP's proprietary base sequence
class camera_axi_read_seq extends uvm_sequence #(axi4_master_tx);
    `uvm_object_utils(camera_axi_read_seq)

    // -------------------------------------------------------
    // Knobs controlled by the Virtual Sequence
    // -------------------------------------------------------
    rand bit [31:0] target_addr;
    rand bit [7:0]  burst_length;

    function new(string name = "camera_axi_read_seq");
        super.new(name);
    endfunction

    task body();
        axi4_master_tx req;
        uvm_sequence_item rsp;
        int id;

        req = axi4_master_tx::type_id::create("req");
        
        start_item(req);
        
        // Scoped the enums to avoid APB/AXI package collisions
        if(!req.randomize() with {
            tx_type       == axi4_globals_pkg::READ;              
            arsize        == axi4_globals_pkg::READ_8_BYTES;      
            arburst       == axi4_globals_pkg::READ_INCR;         
            transfer_type == axi4_globals_pkg::OUTSTANDING_READ;  
            
            araddr        == target_addr;       
            arlen         == burst_length;      
        }) begin
            `uvm_fatal("CAM_AXI_SEQ", "Randomization of AXI read failed")
        end
        
        `uvm_info("CAM_AXI_SEQ", $sformatf("Initiating AXI Read: %0d beats from Addr: 0x%0h", req.arlen+1, req.araddr), UVM_LOW)
        
        finish_item(req);

        id = req.get_transaction_id();
        get_response(rsp, id);
        
        `uvm_info("CAM_AXI_SEQ", "AXI Read Transaction Complete!", UVM_HIGH)

    endtask
endclass

`endif // CAMERA_AXI_READ_SEQ_SV
