module ram_control
(
  // internal and system
  input n_rst,
  input sys_clk,
  input clk_for_dac,
  input [7:0] data_from_pc,
  input ctrl_ena,
  input data_ena,
  // connect with RAM
  output [12:0] sdram_a,
  output [1:0]  sdram_ba,     // bank address
  inout  [15:0] sdram_dq,     // data i/o
  output        sdram_clk,
  output        sdram_cke,    // clock enable
  output        sdram_we_n,   // write_enable
  output        sdram_cas_n,  // column address strobe command
  output        sdram_ras_n,  // row address strobe command
  output        sdram_cs_n,   // chip select
  // connect with DAC
  output [13:0] dac_d,
  // SBIS BOS - signals related with analog video signal
  output        shp_fpga,     // вход тактов обработки
  output        hd_fpga,      // вход управления горизонтальной развёрткой
  output        pblk_fpga,    // вход импульса гашения
  output        vd_fpga,      // вход управления вертикальной развёрткой
  output        clpdm_fpga,   // вход импульса привязки на входе
  output        shd_fpga,     // вход тактов уровня данных
  output        clpob_fpga,   // вход импульса привязки на выходе
  // SBIS BOS - parallel output
  input  [11:0] q_fpga,       // parallel video data from sbis bos
  input         dataclk_fpga,
  // SBIS BOS - serial output
  output        slv_fpga,     // SPI video - cs      
  output        sckv_fpga,    // SPI video - sclk    // 48 MHz
  input         sdatav_fpga   // SPI video - miso
);

fifo_trans_w #
(
  .SIZE       (8),  // less than 8 doesn't work with parametrized fifo
  .WIDTH_IN   (8),
  .WIDTH_OUT  (16),
  .SHOW_AHEAD ("OFF")
)
fifo_from_pc
(
  .aclr (!n_rst),
	.data (data_from_pc),
	.rdclk(),
	.rdreq(),
	.wrclk(sys_clk),
	.wrreq(data_ena),
	
  .q      (),
	.rdempty(),
	.rdusedw(),
	.wrfull ()  
);



endmodule