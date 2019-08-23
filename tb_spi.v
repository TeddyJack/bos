`timescale 1 ns / 1 ns

module tb_spi();

reg clk;
reg [7:0] in_data;
reg in_ena;
reg miso;
reg n_rst;
reg rd_req;

wire        have_msg;
wire        cs;
wire        mosi;
wire        sclk;
wire [7:0]  out_data;
wire        out_ena;
wire        my_busy;
wire        my_empty;
wire [15:0] my_fifo_q;
wire        my_go;
wire [15:0] my_datao;
wire        my_done;
wire        my_datao_ena;


if_spi i1 (
	.clk          (clk),
	.cs           (cs),
	.have_msg     (have_msg),
	.in_data      (in_data),
	.in_ena       (in_ena),
  .rd_req       (rd_req),
	.miso         (miso),
	.mosi         (mosi),
	.my_busy      (my_busy),
	.my_empty     (my_empty),
	.my_fifo_q    (my_fifo_q),
	.my_go        (my_go),
	.n_rst        (n_rst),
	.out_data     (out_data),
	.out_ena      (out_ena),
	.sclk         (sclk),
  .my_datao     (my_datao),
  .my_done      (my_done),
  .my_datao_ena (my_datao_ena)
);


always #10 clk = !clk;

always@(negedge sclk)
  miso = $random;

initial                                                
begin
  n_rst = 1;
  clk = 0;
  in_ena = 0;
  miso = 0;
  in_data = {8{1'bx}};
  rd_req = 0;
  
  
  #1000
  in_ena = 1;
  in_data = 8'h01; #20;
  in_data = 8'h02; #20;
  in_data = 8'h03; #20;
  in_data = 8'h04; #20;
  in_data = 8'h05; #20;
  in_data = 8'h06; #20;
  in_ena = 0;
  in_data = {8{1'bx}};
  
  #50000
  
  rd_req = 1; #(8*20);
  rd_req = 0;
  
  #50000
  
  $display("Testbench end");
  $stop;
end


endmodule