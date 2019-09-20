`timescale 1 ns / 1 ns

module tb_spi_multi();

reg clk;
reg n_rst;

wire sclk;
wire mosi;
reg miso;
wire [2:0]  n_cs_bus;

reg [7:0] m_din;
reg [2:0] m_wrreq_bus;

wire [23:0]  s_dout_bus;
wire [23:0]  len_bus;
wire [2:0]  have_msg_bus;
reg [2:0] s_rdreq_bus;

wire [1:0] select;

                       
if_spi_multi i1 (
	.clk(clk),
	.have_msg_bus (have_msg_bus),
	.len_bus      (len_bus),
	.m_din        (m_din),
	.m_wrreq_bus  (m_wrreq_bus),
	.miso         (miso),
	.mosi         (mosi),
	.n_cs_bus     (n_cs_bus),
	.n_rst        (n_rst),
	.s_dout_bus   (s_dout_bus),
	.s_rdreq_bus  (s_rdreq_bus),
	.sclk         (sclk),
  .my_select    (select)
);


always #10 clk = !clk;

always@(negedge sclk)
  miso = $random;

initial                                                
begin
  n_rst = 1;
  clk = 0;
  m_wrreq_bus = 0;
  miso = 0;
  m_din = {8{1'bx}};
  s_rdreq_bus = 0;
  
  
  #1000
  m_wrreq_bus[1] = 1;
  m_din = 8'h01; #20;
  m_din = 8'h02; #20;
  m_din = 8'h03; #20;
  m_din = 8'h04; #20;
  m_din = 8'h05; #20;
  m_din = 8'h06; #20;
  m_wrreq_bus[1] = 0;
  m_din = {8{1'bx}};
  
  #1000
  m_wrreq_bus[2] = 1;
  m_din = 8'h0A; #20;
  m_din = 8'h0B; #20;
  m_din = 8'h0C; #20;
  m_din = 8'h0D; #20;
  m_wrreq_bus[2] = 0;
  m_din = {8{1'bx}};
  
  #50000
  
  s_rdreq_bus[1] = 1; #(6*20);
  s_rdreq_bus[1] = 0;
  
  #50000
  
  $display("Testbench end");
  $stop;
end


endmodule

