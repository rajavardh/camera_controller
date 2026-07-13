//==============================================================================
//  File        : irq_sync_fast_to_slow.sv
//  Description : Interrupt pulse stretcher for clock domain crossing
//  Author      : payelnath
//  Created     : 2025-05-22
//  Version     : 1.0
//==============================================================================
//  MODULE FUNCTIONALITY
//------------------------------------------------------------------------------
//  - This module is designed to stretch a short pulse (interrupt signal)
//    generated in a fast clock domain so that it can be reliably sampled in a
//    slower destination clock domain.
//
//  - The output is held high for a programmable number of slow-clock cycles.
//
//  - Ensures that fast IRQ pulses are not missed in the slower domain,
//    especially during clock domain crossing.
//
//  - After stretching, the signal is passed through a standard double-flop
//    synchronizer to ensure metastability protection in the slow domain.
//
//------------------------------------------------------------------------------
//  Ports:
//        clk_fast          : Source (fast) clock domain
//        irq_fast          : Interrupt pulse (1-cycle pulse in clk_fast domain)
//        clk_slow          : Destination (slow) clock domain
//        rst_n             : Asynchronous active-low reset
//        irq_slow_pulse    : Stretched interrupt output in slow domain
//
//==============================================================================

`timescale 1 ns / 1 ps

module irq_sync_fast_to_slow (
    input  wire clk_fast,       
    input  wire clk_slow,       
    input  wire rst_n,            
    input  wire irq_fast,         
    output wire irq_slow_pulse    
);


    // ----------------------------------------
    // 1. Stretch the pulse in the fast clk domain
    // ----------------------------------------
    parameter STRETCH_CYCLES = 4; 
    reg [$clog2(STRETCH_CYCLES):0] counter;
    reg irq_stretch;

    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n) begin
            counter     <= 0;
            irq_stretch <= 0;
        end else if (irq_fast) begin
            counter     <= STRETCH_CYCLES - 1;
            irq_stretch <= 1;
        end else if (counter > 0) begin
            counter <= counter - 1;
        end else begin
            irq_stretch <= 0;
        end
    end

    // ----------------------------------------
    // 2. Synchronize to slow clk domain
    // ----------------------------------------
    reg sync_0, sync_1;

    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 0;
            sync_1 <= 0;
        end else begin
            sync_0 <= irq_stretch;
            sync_1 <= sync_0;
        end
    end

    // ----------------------------------------
    // 3. Edge Detection in slow clk domain
    // ----------------------------------------
    assign irq_slow_pulse = sync_0 & ~sync_1;

endmodule

