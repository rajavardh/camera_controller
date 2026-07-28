`ifndef CAMERA_AXI_READ_SEQ_SV
`define CAMERA_AXI_READ_SEQ_SV

class camera_axi_read_seq extends uvm_sequence #(axi4_master_tx);
    `uvm_object_utils(camera_axi_read_seq)

    rand bit [31:0] target_addr;

    function new(string name = "camera_axi_read_seq");
        super.new(name);
    endfunction

    task body();
        axi4_master_tx req;
        uvm_sequence_item rsp;
        int current_addr;

        current_addr = target_addr;

        for (int i = 0; i < 4; i++) begin
            req = axi4_master_tx::type_id::create("req");
            start_item(req);
            
            // Randomize empty to satisfy VIP base rules
            if(!req.randomize()) begin
                `uvm_error("CAM_AXI_SEQ", "VIP Base Randomization failed!")
            end
            
            // Procedural assignments bypass the constraint solver entirely
            req.tx_type       = axi4_globals_pkg::READ;              
            req.arsize        = axi4_globals_pkg::READ_16_BYTES;       
            req.arburst       = axi4_globals_pkg::READ_INCR;         
            req.transfer_type = axi4_globals_pkg::NON_OUTSTANDING_READ;  
            
            req.araddr        = current_addr;       
            req.arlen         = 8'd59; 
            req.arid          = axi4_globals_pkg::ARID_0; 
            
            finish_item(req);
            get_response(rsp, req.get_transaction_id());

            // Advance address by 15 beats * 16 bytes per beat = 240 bytes
            current_addr = current_addr + 240; 
        end
    endtask
endclass

`endif // CAMERA_AXI_READ_SEQ_SV
