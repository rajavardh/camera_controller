`ifndef DVP_SEQUENCE_SV
`define DVP_SEQUENCE_SV

class dvp_sequence extends uvm_sequence #(dvp_seq_item);
    // FIXED: Now perfectly matches the class name
    `uvm_object_utils(dvp_sequence)

    // Sequence configuration (Set these from the test to change frame type)
    cam_resolution_e target_res = RES_VGA;
    cam_format_e     target_fmt = FMT_RGB888;

    // FIXED: Updated the default name to match as well
    function new(string name = "dvp_sequence");
        super.new(name);
    endfunction

    virtual task body();
        dvp_seq_item req;
        int total_lines;

        // -----------------------------------------------------------------
        // STEP 1: Use the item's constraints to determine frame size
        // -----------------------------------------------------------------
        dvp_seq_item temp_item = dvp_seq_item::type_id::create("temp_item");
        
        // Randomize the temp item to let UVM calculate pixels_per_line and line_count
        if (!temp_item.randomize() with { res_cfg == local::target_res; }) begin
            `uvm_fatal("DVP_SEQ", "Failed to resolve sequence item constraints!")
        end
        
        // Extract the intelligence from the item!
        total_lines = temp_item.line_count;
        
        `uvm_info("DVP_SEQ", $sformatf("Starting Frame Generation: %0d Lines", total_lines), UVM_LOW)

        // -----------------------------------------------------------------
        // STEP 2: Generate the Frame Line-by-Line
        // -----------------------------------------------------------------
        for (int line = 0; line < total_lines; line++) begin
            req = dvp_seq_item::type_id::create("req");
            
            start_item(req);
            
            // Randomize the actual payload with frame markers
            if (!req.randomize() with {
                res_cfg           == local::target_res;
                format_cfg        == local::target_fmt;
                
                // Set metadata flags for the driver
                is_start_of_frame == (line == 0);
                is_end_of_frame   == (line == (total_lines - 1));
            }) begin
                `uvm_error("DVP_SEQ", "Failed to randomize active line!")
            end
            
            finish_item(req);
        end
        
        `uvm_info("DVP_SEQ", "Frame Transmission Complete.", UVM_LOW)
    endtask
endclass

`endif // DVP_SEQUENCE_SV
