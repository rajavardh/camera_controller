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
        semaphore data_done ; 
        
	current_addr = target_addr;
        data_done = new(0); 

        fork
            begin : RESPONSE_CONSUMER_LOOP
                uvm_sequence_item rsp;
                axi4_master_tx axi_rsp_pkt;

                for (int j = 0; j < 8; j++) begin
                    get_response(rsp); 
                    
                    if ($cast(axi_rsp_pkt, rsp)) begin
                        `uvm_info("CAM_AXI_SEQ", $sformatf("[BURST DETECTED] Index: %0d | Base Address: 'h%0h ", j, axi_rsp_pkt.araddr), UVM_LOW)
                        
                        axi_rsp_pkt.print(); 
                    end 
                    else begin
                        `uvm_error("CAM_AXI_SEQ", "Polymorphic casting failed! Response object type mismatch.")
                    end
                    
                    data_done.put(1);  
                end
            end
        join_none 
         

        for (int i = 0; i < 8; i++) begin
            req = axi4_master_tx::type_id::create("req");
            
            start_item(req);
            
            if(!req.randomize() with {
                tx_type       == axi4_globals_pkg::READ;              
                arsize        == axi4_globals_pkg::READ_16_BYTES;       
                arburst       == axi4_globals_pkg::READ_INCR;         
                transfer_type == axi4_globals_pkg::OUTSTANDING_READ;  
                araddr        == local::current_addr;       
                arlen         == 8'd7; // 8 beats per burst
                arid        == axi4_globals_pkg::ARID_0; 
            }) begin
                `uvm_error("CAM_AXI_SEQ", "VIP Unified Randomization failed!")
            end
            
            finish_item(req);

            current_addr = current_addr + 128;
        end
        `uvm_info("CAM_AXI_SEQ", "Waiting for all data bursts to return...", UVM_LOW)
        data_done.get(8); 
        `uvm_info("CAM_AXI_SEQ", "All data bursts received for this line.", UVM_LOW)
    endtask
endclass 

`endif // CAMERA_AXI_READ_SEQ_SV
