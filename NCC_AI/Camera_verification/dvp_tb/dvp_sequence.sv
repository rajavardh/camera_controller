`ifndef DVP_SEQUENCE_SV
`define DVP_SEQUENCE_SV

class dvp_sequence extends uvm_sequence #(dvp_seq_item);

    `uvm_object_utils(dvp_sequence)

    rand cam_resolution_e target_res = RES_VGA;
    rand cam_format_e     target_fmt = FMT_RGB888;

    function new(string name = "dvp_sequence");
        super.new(name);
    endfunction

   virtual task body();
        dvp_seq_item req;
        int total_lines;

        dvp_seq_item temp_item = dvp_seq_item::type_id::create("temp_item");
        
        if (!temp_item.randomize() with { res_cfg == local::target_res; }) begin
            `uvm_fatal("DVP_SEQ", "Failed to resolve sequence item constraints!")
        end
        
        total_lines = temp_item.line_count;
        
        `uvm_info("DVP_SEQ", $sformatf("Starting Frame Generation: %0d Lines", total_lines), UVM_LOW)

        for (int line = 0; line < total_lines; line++) begin
            req = dvp_seq_item::type_id::create("req");
            
            start_item(req);
            
            if (!req.randomize() with {
                res_cfg           == local::target_res;
                format_cfg        == local::target_fmt;
                
                is_start_of_frame == (line == 0);
                is_end_of_frame   == (line == (total_lines - 1));
            }) begin
                `uvm_error("DVP_SEQ", "Failed to randomize active line!")
            end
            
            foreach (req.dvp_data_bytes[i]) begin
                req.dvp_data_bytes[i] = i[7:0]; 
            end
            
            req.line_id = line; 
            
            finish_item(req);
        end
        
        `uvm_info("DVP_SEQ", "Frame Transmission Complete.", UVM_LOW)
    endtask
endclass

`endif // DVP_SEQUENCE_SV
