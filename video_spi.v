module video_spi (
  input             n_rst,
  input             sclk_full,
  input             enable,
  
  output reg [11:0] parall_data,
  
  inout             sdatav_fpga,
  output            slv_fpga,
  output            sckv_fpga,
  
  input             dataclk_fpga
);



spi_master_reg #(
  .CPOL (1),
  .CPHA (0),
  .WIDTH (24),
  .PAUSE (3), // actual pause will be +1
  .BIDIR (1),
  .SWAP_DIR_BIT_NUM (8),
  .SCLK_CONST (1)
)
spi_master_reg (
  .n_rst (n_rst),
  .sys_clk (sclk_full),
  .sclk (sckv_fpga),
  .n_cs (slv_fpga),
  .sdio (sdatav_fpga),
  .in_data ({1'b1,23'b0}),
  .in_ena (enable & rising_dataclk),
  .busy (),
  .miso_reg (miso_reg),
  .miso_reg_ena (miso_reg_ena)
);



wire [23:0] miso_reg;
wire miso_reg_ena;

always@(posedge sclk_full or negedge n_rst)
  if(!n_rst)
    parall_data <= 0;
  else
    if(miso_reg_ena)
      parall_data <= miso_reg[11:0];


reg rising_dataclk;
reg delayed_dataclk;
always @ (posedge sclk_full or negedge n_rst)
  if (!n_rst)
    begin
    rising_dataclk <= 0;
    delayed_dataclk <= 0;
    end
  else
    begin
    delayed_dataclk <= dataclk_fpga;
    rising_dataclk <= dataclk_fpga & !delayed_dataclk;
    end
    




endmodule