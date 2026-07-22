class dma_item extends uvm_sequence_item;
    `uvm_object_utils(dma_item)

    bit [1:0] dma_trig_req_type; 
    bit [1:0] dma_trig_ack_type; 

    function new(string name = "dma_item");
        super.new(name);
    endfunction
endclass

