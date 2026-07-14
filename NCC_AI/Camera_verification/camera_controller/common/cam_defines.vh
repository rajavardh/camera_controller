//0###################################################################################################
//`define DV_SIM
//`define FPGA                              

//0###################################################################################################
//MEMORY CUT DEFINES
//0###################################################################################################
`define ARM_UD_MODEL
`define ARM_UD_SEQ
`define ARM_DISABLE_EMA_CHECK
`define INCLUDE_SDIPS_I2S_DEFINES
`define INCLUDE_SDIPS_SPI_MASTER_DEFINES
`define ASIC_MEM

//SPI
`define SDIPS_NO_BLACKBOX

//PLL
`define SICR_INITIAL_PWR_CHECKS

//`define VOLTAGE_08V
// If VOLTAGE_08V is defined, use 0.8V values; else default to 0.9V

`ifdef VOLTAGE_08V
//ROM
  `define EMA_VALUE_ROM       3'b011
  // SP SRAM
  `define EMA_VALUE_SP       3'b100
  `define EMAW_VALUE_SP      2'b00
  `define EMAS_VALUE_SP      1'b0

  // SP Control Signals
  `define SP_WABL_VALUE      1'b1
  `define SP_WABLM_VALUE     2'b00
  `define SP_RAWL_VALUE      1'b1
  `define SP_RAWLM_VALUE     2'b01

  // DP SRAM Port A
  `define EMAA_VALUE_DP      3'b100
  `define EMAWA_VALUE_DP     2'b10
  `define EMASA_VALUE_DP     1'b0

  // DP SRAM Port B
  `define EMAB_VALUE_DP      3'b100
  `define EMAWB_VALUE_DP     2'b10
  `define EMASB_VALUE_DP     1'b0

`else

   //ROM
  `define EMA_VALUE_ROM       3'b010

  // SP SRAM
  `define EMA_VALUE_SP       3'b011
  `define EMAW_VALUE_SP      2'b01
  `define EMAS_VALUE_SP      1'b0

  // SP Control Signals
  `define SP_RAWL_VALUE      1'b0
  `define SP_RAWLM_VALUE     2'b00
  `define SP_WABL_VALUE      1'b1
  `define SP_WABLM_VALUE     2'b00

  // DP SRAM Port A
  `define EMAA_VALUE_DP      3'b011
  `define EMAWA_VALUE_DP     2'b10
  `define EMASA_VALUE_DP     1'b0

  // DP SRAM Port B
  `define EMAB_VALUE_DP      3'b011
  `define EMAWB_VALUE_DP     2'b10
  `define EMASB_VALUE_DP     1'b0

`endif

