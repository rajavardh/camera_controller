`ifndef DMA_BASE_SEQ_SV
`define DMA_BASE_SEQ_SV

class dma_base_seq extends uvm_sequence#(dma_seq_item);
    `uvm_object_utils(dma_base_seq)

    dma_action_e seq_action;
    bit [1:0]    seq_ack_type;
    bit [1:0]    dma_req_ack_type; 

    function new(string name = "dma_base_seq");
        super.new(name);
    endfunction

    virtual task body();
        dma_seq_item item;
        item = dma_seq_item::type_id::create("item");
        
        start_item(item);
        item.action          = this.seq_action;
        item.target_ack_type = this.seq_ack_type;
        finish_item(item); 
        
        this.dma_req_ack_type = item.dma_trig_req_type;
        
        `uvm_info("DMA_SEQ", $sformatf("DMA Step %s done. Sampled Type: %0b", 
                  seq_action.name(), this.dma_req_ack_type), UVM_MEDIUM)
    endtask
endclass

`endif // DMA_BASE_SEQ_SV

