// =================================================================================================
// Module: sram_8KB
//
// Description:
//   Behavioral model of a 128b-wide, 512-deep (8KB) single-port SRAM macro, standing in for the
//   real memory compiler instance behind sram_wrapper. Used as both ping/pong camera line buffers
//   (see CCM spec section 6.31, Fig 6-6) via sram_wrapper.
//
//   Port semantics (matching how sram_wrapper drives them from mem_wen[15:0]):
//     - cen  : active-low chip enable - no access at all while high.
//     - gwen : active-low global write enable - sram_wrapper derives this as &mem_wen, i.e. it is
//              asserted (0) whenever ANY byte lane wants to write, and deasserted (1, read) only
//              when no byte lane is being written.
//     - wen  : active-low, per-bit mask (128b, byte-replicated by sram_wrapper from mem_wen[15:0])
//              selecting exactly which bytes actually get written once gwen indicates write mode.
//     - q    : synchronous (registered), read-first - reflects the addressed word as it stood
//              before any write applied on the same cycle, matching typical SRAM compiler timing.
//     - ema/emaw/emas/stov/ret1n: memory-compiler margin/test/retention pins with no functional
//       effect on read/write data in this behavioral model; ret1n freezes the array (retention)
//       when deasserted, matching real macros holding state with the clock stopped.
// =================================================================================================
//
`timescale 1 ns / 1 ps

module sram_8KB (q, clk, cen, gwen, a, d, wen, stov, ema, emaw, emas, ret1n);

  input          clk;
  input          cen;
  input          gwen;
  input  [8:0]   a;
  input  [127:0] d;
  input  [127:0] wen;
  input          stov;
  input  [2:0]   ema;
  input  [1:0]   emaw;
  input          emas;
  input          ret1n;
  output [127:0] q;

  // Unused in this behavioral model - real memory-compiler margin/test pins
  // (stov, ema, emaw, emas)

  reg [127:0] mem [0:511];
  reg [127:0] q_r;
  integer     i;

  initial
    for (i = 0; i < 512; i = i + 1)
      mem[i] = 128'h0; // deterministic power-up contents for simulation

  always @(posedge clk) begin
    if (ret1n && !cen) begin
      if (!gwen)
        for (i = 0; i < 128; i = i + 1)
          if (!wen[i])
            mem[a][i] <= d[i];
      q_r <= mem[a]; // read-first: reflects pre-write contents of this cycle
    end
  end

  assign q = q_r;

endmodule
