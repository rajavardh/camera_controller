`ifndef CAMERA_AXI_READ_SEQ_SV
`define CAMERA_AXI_READ_SEQ_SV

class camera_axi_read_seq extends axi4_master_base_seq;
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
        
        // Randomize the VIP's req item using our custom knobs
        if(!req.randomize() with {
            req.tx_type       == READ;              // VIP Enum for Read
            req.arsize        == READ_8_BYTES;      // 64-bit data width (Change to READ_16_BYTES if 128-bit!)
            req.arburst       == READ_INCR;         // Incremental burst
            req.transfer_type == OUTSTANDING_READ;  // VIP Enum for outstanding

            // ---> THE CRITICAL ADDITIONS <---
            req.araddr        == target_addr;       // Point to the ping-pong buffer!
            req.arlen         == burst_length;      // Tell it how many beats to read!
        }) begin
            `uvm_fatal("CAM_AXI_SEQ", "Randomization of AXI read failed")
        end
        
        `uvm_info("CAM_AXI_SEQ", $sformatf("Initiating AXI Read: %0d beats from Addr: 0x%0h", req.arlen+1, req.araddr), UVM_LOW)
        
        finish_item(req);

        // Crucial: The VIP Driver sends a response back when the read finishes.
        // We must pull it out of the queue, otherwise the sequencer gets clogged!
        id = req.get_transaction_id();
        get_response(rsp, id);
        
        `uvm_info("CAM_AXI_SEQ", "AXI Read Transaction Complete!", UVM_HIGH)

    endtask
endclass

`endif // CAMERA_AXI_READ_SEQ_SV
