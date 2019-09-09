`timescale 1 ns / 1 ns

module tb_spi_multi();

reg           clk;
reg           n_rst;

wire          sclk;
wire          mosi;
reg           miso;
wire  [2:0]   n_cs_bus;

reg   [7:0]   m_din;
reg   [2:0]   m_wrreq;

wire  [23:0]  s_dout;
wire  [23:0]  len;
wire  [2:0]   have_msg;
reg   [2:0]   s_rdreq;

wire  [1:0]   my_select;
wire  [15:0]  my_m_dout;
wire  [2:0]   my_m_rdreq;
wire  [2:0]   my_m_empty;

wire  [15:0]  my_s_din;
wire  [2:0]   my_s_wrreq;

wire          my_busy;
wire          my_cur_m_empty;
wire          my_go;

if_spi_multi i1
(
	.clk        (clk),
	.have_msg   (have_msg),
	.len        (len),
	.m_din      (m_din),
	.m_wrreq    (m_wrreq),
	.miso       (miso),
	.mosi       (mosi),
	.n_cs_bus   (n_cs_bus),
	.n_rst      (n_rst),
	.s_dout     (s_dout),
	.s_rdreq    (s_rdreq),
	.sclk       (sclk),
  .my_select  (my_select),
  .my_m_dout  (my_m_dout),
  .my_m_rdreq (my_m_rdreq),
  .my_m_empty (my_m_empty),
  .my_s_din   (my_s_din),
  .my_s_wrreq (my_s_wrreq),
  .my_busy    (my_busy),
  .my_cur_m_empty(my_cur_m_empty),
  .my_go      (my_go)
);


always #10 clk = !clk;

always@(negedge sclk)
  miso = $random;

initial                                                
begin
  n_rst = 1;
  clk = 0;
  m_wrreq = 0;
  miso = 0;
  m_din = {8{1'bx}};
  s_rdreq = 0;
  
  
  #1000
  m_wrreq[1] = 1;
  m_din = 8'h01; #20;
  m_din = 8'h02; #20;
  m_din = 8'h03; #20;
  m_din = 8'h04; #20;
  m_din = 8'h05; #20;
  m_din = 8'h06; #20;
  m_wrreq[1] = 0;
  m_din = {8{1'bx}};
  
  #1000
  m_wrreq[2] = 1;
  m_din = 8'h0A; #20;
  m_din = 8'h0B; #20;
  m_din = 8'h0C; #20;
  m_din = 8'h0D; #20;
  m_wrreq[2] = 0;
  m_din = {8{1'bx}};
  
  #50000
  
  s_rdreq[1] = 1; #(6*20);
  s_rdreq[1] = 0;
  
  #50000
  
  $display("Testbench end");
  $stop;
end




endmodule

