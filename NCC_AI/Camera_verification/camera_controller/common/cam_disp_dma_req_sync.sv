// ============================================================================
// Module: cam_disp_dma_req_sync
// ----------------------------------------------------------------------------
// Description:
// This module synchronizes DMA trigger request signals and request types from
// the source clock domain to the destination clock domain (typically the DMA clock).
// It instantiates two mux_synchronizer modules:
// 1. One for camera DMA trigger request (cam_dma_trig_req)
// 2. One for display DMA trigger request (disp_dma_trig_req)
//
//
// Key Features:
// - Parameterizable data width for trigger type
// - Optional pulse extension logic
// - Configurable number of synchronizing flip-flops
//
// Parameters:
// - DATA_WIDTH:     Width of the DMA trigger request type signal
// - EXTEND_CYCLES:  Pulse extension cycles (when enabled)
// - SYNC_FLOPS:     Number of flip-flops for CDC synchronization
// - EN_PULSE_EXT:   Enable pulse extension and edge detection
// ============================================================================

`timescale 1 ns / 1 ps

module cam_disp_dma_req_sync #(
    parameter int DATA_WIDTH = 2,
    parameter int EXTEND_CYCLES = 3,
    parameter int SYNC_FLOPS = 2,
    parameter bit EN_PULSE_EXT = 0
) (
    // Clock and Reset
    input  logic                  src_clk,                    // Source clock domain
    input  logic                  dst_clk,                    // Destination clock domain (DMA clock)
    input  logic                  rst_n,                      // Reset signal
    
    // Camera Interface
    input  logic                  cam_dma_trig_req,           // Camera DMA trigger request
    input  logic [DATA_WIDTH-1:0] cam_dma_trig_req_type,      // Camera DMA trigger request type
    output logic                  cam_dma_trig_req_sync,      // Synchronized camera DMA trigger request
    output logic [DATA_WIDTH-1:0] cam_dma_trig_req_type_sync, // Synchronized camera DMA trigger request type
    
    // Display Interface
    input  logic                  disp_dma_trig_req,          // Display DMA trigger request
    input  logic [DATA_WIDTH-1:0] disp_dma_trig_req_type,     // Display DMA trigger request type
    output logic                  disp_dma_trig_req_sync,     // Synchronized display DMA trigger request
    output logic [DATA_WIDTH-1:0] disp_dma_trig_req_type_sync // Synchronized display DMA trigger request type
);

    // Camera synchronizer instance
    mux_synchronizer #(
        .DATA_WIDTH(DATA_WIDTH),
        .EXTEND_CYCLES(EXTEND_CYCLES),
        .SYNC_FLOPS(SYNC_FLOPS),
        .EN_PULSE_EXT(EN_PULSE_EXT)
    ) u_sync_cam_req (
        .src_clk       (src_clk),
        .dst_clk       (dst_clk),
        .rst_n         (rst_n),
        .en_in         (cam_dma_trig_req),
        .en_sync_out   (cam_dma_trig_req_sync),
        .dataIn        (cam_dma_trig_req_type),
        .dataOut       (cam_dma_trig_req_type_sync)
    );

    // Display synchronizer instance
    mux_synchronizer #(
        .DATA_WIDTH(DATA_WIDTH),
        .EXTEND_CYCLES(EXTEND_CYCLES),
        .SYNC_FLOPS(SYNC_FLOPS),
        .EN_PULSE_EXT(EN_PULSE_EXT)
    ) u_sync_disp_req (
        .src_clk       (src_clk),
        .dst_clk       (dst_clk),
        .rst_n         (rst_n),
        .en_in         (disp_dma_trig_req),
        .en_sync_out   (disp_dma_trig_req_sync),
        .dataIn        (disp_dma_trig_req_type),
        .dataOut       (disp_dma_trig_req_type_sync)
    );

endmodule
