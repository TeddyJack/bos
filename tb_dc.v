`timescale 1 ns / 1 ns

module tb_dc();

reg nrst;
reg clk;
reg [7:0] rx_data;
reg rx_valid;

wire [7:0]  q;
wire [7:0]  my_cnt;
wire [7:0]  my_dest;
wire [7:0]  my_len;
wire [2:0]  my_state;
wire        rx_ready;
wire [4:0]  valid_bus;
wire [7:0]  my_crc_calcked;
wire        my_rdreq;
wire        my_empty;
wire        my_rst_timeout;
wire [31:0] my_cnt_timeout;


cmd_decoder i1 (
  .nrst           (nrst),
	.clk            (clk),
	.q              (q),
	.my_cnt         (my_cnt),
	.my_dest        (my_dest),
	.my_len         (my_len),
	.my_state       (my_state),
	.rx_data        (rx_data),
	.rx_ready       (rx_ready),
	.rx_valid       (rx_valid),
	.valid_bus      (valid_bus),
  .my_crc_calcked (my_crc_calcked),
  .my_rdreq       (my_rdreq),
  .my_empty       (my_empty),
  .my_rst_timeout (my_rst_timeout),
  .my_cnt_timeout (my_cnt_timeout)
);

task automatic send_data;
  input [7:0] value;
  integer i;
  begin: t1
    rx_valid = 1; rx_data = value; #20;
    rx_valid = 0; rx_data = {8{1'bx}}; #(3500*20-20);
  end
endtask

always #10 clk = !clk;

initial                                                
begin
  nrst = 1;
  clk = 0;
  rx_data = {8{1'bx}};
  rx_valid = 0;
  #50000
  send_data(8'hDD);   // prefix
  send_data(8'h01);   // ast address
  send_data(8'h04);   // dest
  send_data(8'h06);   // len
  send_data(8'h01);
  send_data(8'h02);
  send_data(8'h03);
  #1200000         // to test timeout
  send_data(8'h04);
  send_data(8'h05);
  send_data(8'h06);
  send_data(8'h99);   // checksum, correct is 0x15


  
  $display("Testbench end");
  $stop;
end        


endmodule