`timescale 1 ns / 1 ps
`include "defines.v"

module tb_func();

reg  fpga_clk_48;
//reg  fpga_clk_dac;
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

wire [1:0] my_state;
wire my_m_wrreq;
wire [7:0] my_m_used;
wire my_m_rdreq;
wire [15:0] my_m_q;
wire [2:0] my_counter;

wire dac_clk_ext;
wire clk_fpga;
wire shp_fpga;
wire shd_fpga;

bos i1
(
  .fpga_clk_48        (fpga_clk_48),
  //.fpga_clk_dac       (fpga_clk_dac),
  .n_rst              (n_rst),
  .dac_clk_ext        (dac_clk_ext),

  .tx                 (tx),
  .rx                 (rx),


  
  .my_rx_data         (my_rx_data),
  .my_rx_valid        (my_rx_valid),
  .my_master_data     (my_master_data),
  .my_valid_bus       (my_valid_bus),
  .my_tx_data         (my_tx_data),
  .my_tx_valid        (my_tx_valid),
  .my_have_msg_bus    (my_have_msg_bus),
  
  .my_state           (my_state),
  .my_m_wrreq         (my_m_wrreq),
  .my_m_used          (my_m_used),
  .my_m_rdreq         (my_m_rdreq),
  .my_m_q             (my_m_q),
  .my_counter         (my_counter),
  .clk_fpga           (clk_fpga),
  .shp_fpga           (shp_fpga),
  .shd_fpga           (shd_fpga)
);

integer UART_T = 10000000 / 1152;  // in ns

task automatic send_to_rx;
  input [7:0] value;
  integer i;
  begin: t1
    rx = 0; #UART_T;
    for(i=0; i<=7; i=i+1)
    begin: f1
      rx = value[i]; #UART_T;
    end
    rx = 1; #UART_T;
    #(UART_T*3);    // pause between bytes
  end
endtask

real CLK_T = 1000.0 / `SYS_CLK / 2.0;// in ns
always #CLK_T      fpga_clk_48 = !fpga_clk_48;
//always #15.625  fpga_clk_dac = !fpga_clk_dac;


initial
  begin
  $display("sys clk half period = %f\n", CLK_T);
  
  n_rst = 0;
  fpga_clk_48 = 0;
  //fpga_clk_dac = 0;
  rx = 1;
  
  #100
  
  n_rst = 1;

  #10000
  /*
  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h16);  // address of dest
  send_to_rx(8'h01);  // len
  send_to_rx(8'hAE);
  send_to_rx(8'hAE);  // crc
  */
  
  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h14);  // address of dest
  send_to_rx(8'h01);  // len
  send_to_rx(8'hAA);  // start send
  send_to_rx(8'hFF);  // crc
  
  #5000
  
  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h15);  // address of dest
  send_to_rx(8'd40);  // len
  
  send_to_rx(8'h01); send_to_rx(8'h00);
  send_to_rx(8'h03); send_to_rx(8'h02);
  
  send_to_rx(8'h05); send_to_rx(8'h04);
  send_to_rx(8'h07); send_to_rx(8'h06);
  send_to_rx(8'h09); send_to_rx(8'h08);
  send_to_rx(8'h0B); send_to_rx(8'h0A);
  
  send_to_rx(8'h0D); send_to_rx(8'h0C);
  send_to_rx(8'h0F); send_to_rx(8'h0E);
  send_to_rx(8'h11); send_to_rx(8'h10);
  send_to_rx(8'h13); send_to_rx(8'h12);
  
  send_to_rx(8'h15); send_to_rx(8'h14);
  send_to_rx(8'h17); send_to_rx(8'h16);
  send_to_rx(8'h19); send_to_rx(8'h18);
  send_to_rx(8'h1B); send_to_rx(8'h1A);
  
  send_to_rx(8'h1D); send_to_rx(8'h1C);
  send_to_rx(8'h1F); send_to_rx(8'h1E);
  send_to_rx(8'h21); send_to_rx(8'h20);
  send_to_rx(8'h23); send_to_rx(8'h22);
  
  send_to_rx(8'h25); send_to_rx(8'h24);
  send_to_rx(8'h27); send_to_rx(8'h26);
    
  send_to_rx(8'hFF);  // crc
  
  #5000
  
  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h14);  // address of dest
  send_to_rx(8'h01);  // len
  send_to_rx(8'hBB);  // stop send
  send_to_rx(8'hFF);  // crc

  
  #1500000
  
  $display("Testbench end");
  $stop();
  end                            


endmodule
