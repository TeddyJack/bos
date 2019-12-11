`timescale 1 ns / 1 ns
`include "defines.v"

module tb_keep_alive();

reg  fpga_clk_48;
reg  n_rst;

wire tx;
reg  rx;



wire [7:0] my_master_data;
wire [1*`N_SRC-1:0] my_valid_bus;
wire [7:0] my_rx_data;
wire my_rx_valid;
wire [7:0] my_tx_data;
wire my_tx_valid;
wire [1*`N_SRC-1:0] my_have_msg_bus;



bos i1
(
  .fpga_clk_48        (fpga_clk_48),
  .n_rst              (n_rst),

  .tx                 (tx),
  .rx                 (rx),


  
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



initial
  begin
  
  n_rst = 0;
  fpga_clk_48 = 0;
  rx = 1;
  
  #100
  
  n_rst = 1;

  #10000
  
  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h01);  // address of ast
  send_to_rx(8'h13);  // address of dest
  send_to_rx(8'h01);  // len
  send_to_rx(8'hAE);
  send_to_rx(8'hAE);  // crc
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
