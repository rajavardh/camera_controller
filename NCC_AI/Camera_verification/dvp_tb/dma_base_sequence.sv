class dma_base_sequence extends uvm_sequence#(dma_seq_item);
    `uvm_object_utils(dma_base_sequence)

    bit [1:0] dma_req_ack_type;

    function new(string name = "dma_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        dma_seq_item item;
        item = dma_seq_item::type_id::create("item");

        start_item(item);

        finish_item(item); 

        this.dma_req_ack_type = item.dma_trig_req_type;
        
        `uvm_info("DMA_SEQ", $sformatf(" DMA Handshake done . DMA request/ack type: %0b", 
                  this.dma_req_ack_type), UVM_MEDIUM)
    endtask
endclass
