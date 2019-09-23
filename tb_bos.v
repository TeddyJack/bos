`timescale 1 ns / 1 ns
`include "defines.v"

module tb_bos();

reg  fpga_clk_100;
reg  fpga_clk_48;
reg  n_rst;

wire tx;
reg  rx;

wire dac_din;
wire dac_sclk;
wire dac_sync_n;
reg  dac_sdo;
reg  dac_rdy;
wire dac_rst_n;

wire din_power;
wire sclk_power;
wire rst_power_n;
wire sync_core_n;
wire sync_digital_n;
wire sync_vpr_digital_n;

wire adc_sclk_pwr;
wire adc_din_pwr;
reg  adc_dout_pwr;
wire adc_cs_pwr_n;

wire adc_sclk;
wire adc_din;
reg  adc_dout;
wire adc1_cs_n;
wire adc2_cs_n;

wire dds_io_upd;
wire dds_rst;
wire dds_cs_n;
wire dds_sdio;
reg  treg_dds_sdio;
wire dds_sclk;

wire [3:0]  a;
wire load_pr_3v7;
wire load_pdr;
wire dac_gain;
wire dac_switch_out_fpga;
wire dac_ena_out_fpga;
wire off_pr_digital_fpga;
wire functional;
wire off_vcore_fpga;
wire off_vdigital_fpga;

wire sl_fpga;
wire sdatai_fpga;
reg  sdatao_fpga;
wire sck_fpga;

// debug
wire [7:0] my_master_data;
wire [1*`N_SRC-1:0] my_valid_bus;
wire [7:0] my_rx_data;
wire my_rx_valid;
wire [7:0] my_tx_data;
wire my_tx_valid;
wire [1*`N_SRC-1:0] my_have_msg_bus;

// tri-state                       
assign dds_sdio = treg_dds_sdio;

bos i1
(
  .fpga_clk_100       (fpga_clk_100),
  .fpga_clk_48        (fpga_clk_48),
  .n_rst              (n_rst),

  .tx                 (tx),
  .rx                 (rx),

  .dac_din            (dac_din),
  .dac_sclk           (dac_sclk),
  .dac_sync_n         (dac_sync_n),
  .dac_sdo            (dac_sdo),
  .dac_rdy            (dac_rdy),
  .dac_rst_n          (dac_rst_n),

  .din_power          (din_power),
  .sclk_power         (sclk_power),
  .rst_power_n        (rst_power_n),
  .sync_core_n        (sync_core_n),
  .sync_digital_n     (sync_digital_n),
  .sync_vpr_digital_n (sync_vpr_digital_n),

  .adc_sclk_pwr       (adc_sclk_pwr),
  .adc_din_pwr        (adc_din_pwr),
  .adc_dout_pwr       (adc_dout_pwr),
  .adc_cs_pwr_n       (adc_cs_pwr_n),
  
  .adc_sclk           (adc_sclk),
  .adc_din            (adc_din),
  .adc_dout           (adc_dout),
  .adc1_cs_n          (adc1_cs_n),
  .adc2_cs_n          (adc2_cs_n),
  
  .dds_io_upd         (dds_io_upd),
  .dds_rst            (dds_rst),
  .dds_cs_n           (dds_cs_n),
  .dds_sdio           (dds_sdio),
  .dds_sclk           (dds_sclk),
  
  .a                  (a),
  .load_pr_3v7        (load_pr_3v7),
  .load_pdr           (load_pdr),
  .dac_gain           (dac_gain),
  .dac_switch_out_fpga(dac_switch_out_fpga),
  .dac_ena_out_fpga   (dac_ena_out_fpga),
  .off_pr_digital_fpga(off_pr_digital_fpga),
  .functional         (functional),
  .off_vcore_fpga     (off_vcore_fpga),
  .off_vdigital_fpga  (off_vdigital_fpga),
  
  .sl_fpga            (sl_fpga),
  .sdatai_fpga        (sdatai_fpga),
  .sdatao_fpga        (sdatao_fpga),
  .sck_fpga           (sck_fpga),
  
  .my_rx_data         (my_rx_data),
  .my_rx_valid        (my_rx_valid),
  .my_master_data     (my_master_data),
  .my_valid_bus       (my_valid_bus),
  .my_tx_data         (my_tx_data),
  .my_tx_valid        (my_tx_valid),
  .my_have_msg_bus    (my_have_msg_bus)
);


task automatic send_to_rx;
  input [7:0] value;
  integer i;
  begin: t1
    rx = 0; #8680;
    for(i=0; i<=7; i=i+1)
    begin: f1
      rx = value[i]; #8680;
    end
    rx = 1; #8680;
    #(8680*3);    // pause between bytes
  end
endtask

always #10 fpga_clk_48 = !fpga_clk_48;

always@(posedge dac_sclk)
  if(!dac_sync_n)
    dac_sdo = #5 $random;


initial
  begin
  adc_dout = 0;
  adc_dout_pwr = 0;
  dac_rdy = 1;
  dac_sdo = 0;
  treg_dds_sdio = 1'bz;
  fpga_clk_100 = 0;
  sdatao_fpga = 0;
  
  n_rst = 0;
  fpga_clk_48 = 0;
  rx = 1;
  
  #100
  
  n_rst = 1;

  #10000
  
  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h01);  // address of ast
  send_to_rx(8'd00);  // address of dest
  send_to_rx(8'h06);  // len
  send_to_rx(8'h01);
  send_to_rx(8'h02);
  send_to_rx(8'h03);
  send_to_rx(8'h04);
  send_to_rx(8'h05);
  send_to_rx(8'h06);
  send_to_rx(8'h15);  // crc
  /*
  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h01);  // address of ast
  send_to_rx(8'd17);  // address of dest
  send_to_rx(8'h01);  // len
  send_to_rx(8'h01);
  send_to_rx(8'h01);  // crc
  */
  
  #1500000
  
  $display("Testbench end");
  $stop();
  end                            


endmodule
