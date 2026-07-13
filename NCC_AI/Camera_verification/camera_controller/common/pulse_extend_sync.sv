// ============================================================================
// Module: pulse_extend_sync
// ----------------------------------------------------------------------------
// Description:
// This module safely transfers a short pulse from a source clock domain
// to a destination clock domain by first extending the pulse width, then performing
// multi-flop synchronization, and finally detecting the positive edge.
//
// Key Features:
// - Pulse width extension in the source clock domain
// - Configurable multi-flop synchronizer in the destination clock domain
// - Positive edge detection to generate a clean 1-cycle pulse in dst_clk domain
//
// Parameters:
// - EXTEND_CYCLES: Number of cycles to extend the input pulse
// - SYNC_FLOPS:    Number of synchronizing flip-flops for CDC
// ============================================================================


`timescale 1 ns / 1 ps

module pulse_extend_sync #(
    parameter int EXTEND_CYCLES = 3,
    parameter int SYNC_FLOPS    = 2    
   ) (
    input  logic src_clk,      // Source clock (dvp_pclk)
    input  logic dst_clk,      // Destination clock (pclk)
    input  logic rst_n,        // Active-low async reset
    input  logic pulse_in,     // Input pulse from camera data pipe
    output logic pulse_sync_out      // Synchronized output to register module
);

    logic extended_pulse;
    logic sync_ff_out;
    
    // Stage 1: Pulse extension in source clock domain
    pulse_extender #(
        .EXTEND_CYCLES(EXTEND_CYCLES)
    ) u_pulse_extender (
        .clk(src_clk),
        .rst_n(rst_n),
        .pulse_in(pulse_in),
        .pulse_out(extended_pulse)
    );
    
    // Stage 2: Clock domain crossing with 2FF synchronizer
    rjn_sync_ff #(
        .NUM_FLOPS(SYNC_FLOPS),
        .RST_VAL(1'b0)
    ) u_sync_ff (
        .clk(dst_clk),
        .rst_n(rst_n),
        .async_in(extended_pulse),
        .sync_out(sync_ff_out)
    );

    // Stage 3: Positive edge detector
    logic sync_ff_out_delayed;
    
    always_ff @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff_out_delayed <= 1'b0;
        end else begin
            sync_ff_out_delayed <= sync_ff_out;
        end
    end
    
    // Positive edge detection
    assign pulse_sync_out = sync_ff_out & ~sync_ff_out_delayed;

endmodule
