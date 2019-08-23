`timescale 1 ns / 1 ns

module testbench();

reg        fpga_clk_48;
reg        rx;
wire       tx;
wire [7:0] my_rx_data;
wire       my_rx_valid;
wire       my_tx_ready;
wire [7:0] my_tx_data;
wire       my_tx_valid;
wire       my_rx_ready;

wire [4:0]     ready_bus;
wire [5*8-1:0] data_bus;
wire [4:0]     valid_bus;
wire [2:0]      my_state;
wire [7:0]      my_dest;
wire [7:0]      my_len;
wire [7:0]      my_cnt;

bos i1 (
	.fpga_clk_48 (fpga_clk_48),
	.rx          (rx),
	.tx          (tx),
  .my_rx_data  (my_rx_data),
  .my_rx_valid (my_rx_valid),
  .my_tx_ready (my_tx_ready),
  .my_tx_data  (my_tx_data),
  .my_tx_valid (my_tx_valid),
  .my_rx_ready (my_rx_ready),
  
  .ready_bus (ready_bus),
  .data_bus  (data_bus),
  .valid_bus (valid_bus),
  // debug
  .my_state  (my_state),
  .my_dest   (my_dest),
  .my_len    (my_len),
  .my_cnt    (my_cnt)
);


task automatic send_to_rx;
  input [7:0] value;
  integer i;
  begin: t1
    rx = 0; #7000;
    for(i=0; i<=7; i=i+1)
    begin: f1
      rx = value[i]; #7000;
    end
    rx = 1; #7000;
    #(7000*3);
  end
endtask

always #10 fpga_clk_48 = !fpga_clk_48;


initial                                                
begin
  fpga_clk_48 = 0;
  rx = 1;
  #100

  send_to_rx(8'hDD);  // prefix
  send_to_rx(8'h01);  // address of ast
  send_to_rx(8'd02);  // address of dest
  send_to_rx(8'h06);  // len
  send_to_rx(8'h01);
  send_to_rx(8'h02);
  send_to_rx(8'h03);
  send_to_rx(8'h04);
  send_to_rx(8'h05);
  send_to_rx(8'h06);
  
  $display("Testbench end");
  $stop;
end                                                    


endmodule

