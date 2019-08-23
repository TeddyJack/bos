`timescale 1 ns / 1 ns
`include "defines.v"

module tb_enc();

reg miso;
reg clk;
reg n_rst;
reg rx;

wire cs_n;
wire mosi;
wire sclk;
wire [7:0]  my_cnt;
wire [2:0]  my_current_source;
wire [2:0]  my_state;
wire tx;
wire [7:0] my_rx_data;
wire my_rx_valid;
wire [7:0] my_tx_data;
wire my_tx_valid;
wire my_tx_ready;
wire [1*`NUM_SOURCES-1:0] my_rdreq_bus;
wire [7:0]  my_crc;
wire [1*`NUM_SOURCES-1:0] my_have_msg_bus;
wire [8*`NUM_SOURCES-1:0] my_len_bus;



bos i1
(
  .adc1_cs_n        (cs_n),
  .adc_din          (mosi),
  .adc_dout         (miso),
  .adc_sclk         (sclk),
  .fpga_clk_48      (clk),
  .my_cnt           (my_cnt),
  .my_current_source(my_current_source),
  .my_state         (my_state),
  .n_rst            (n_rst),
  .rx               (rx),
  .tx               (tx),
  .my_rx_data       (my_rx_data),
  .my_rx_valid      (my_rx_valid),
  .my_tx_data       (my_tx_data),
  .my_tx_valid      (my_tx_valid),
  .my_tx_ready      (my_tx_ready),
  .my_rdreq_bus     (my_rdreq_bus),
  .my_crc           (my_crc),
  .my_have_msg_bus  (my_have_msg_bus),
  .my_len_bus       (my_len_bus)
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


always #10 clk = !clk;


always@(negedge sclk)
  miso = $random;

  

initial                                                
begin
  n_rst = 1;
  clk = 0;
  miso = 0;
  rx = 1;

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
  send_to_rx(8'h15);  // must be 8'h15
  
  #3000000
  
  $display("Testbench end");
  $stop;
end


endmodule