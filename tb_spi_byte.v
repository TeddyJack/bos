`timescale 1 ns / 1 ns

module tb_spi_byte();

reg n_rst;
reg clk;
reg have_data;
wire my_ena;
wire mosi;
wire sclk;
wire cs_n;
wire io_update;
wire rdreq;
reg [7:0] data_i;
wire my_state;
wire [2:0] my_cnt_bit;
wire [7:0] my_mosi_reg;
wire [7:0]  miso_reg;
wire wrreq;
reg miso;
wire my_load_cond;
wire high_z;





// assign statements (if any)                          
spi_master_9952 i1 (
// port map - connection between master ports and signals/registers   
	.clk         (clk),
	.cs_n        (cs_n),
	.data_i      (data_i),
	.have_data   (have_data),
	.io_update   (io_update),
	.miso        (miso),
	.miso_reg    (miso_reg),
	.mosi        (mosi),
	.rdreq       (rdreq),
	.rst         (n_rst),
	.sclk        (sclk),
	.wrreq       (wrreq),
  .my_ena      (my_ena),
  .my_state    (my_state),
  .my_cnt_bit  (my_cnt_bit),
  .my_mosi_reg (my_mosi_reg),
  .my_load_cond(my_load_cond),
  .high_z      (high_z)
);


always #10 clk = !clk;

always@(posedge sclk)
if(!cs_n)
  miso = #5 $random;
  
always@(posedge clk)
if(rdreq)
  data_i <= #5 /*$random*//*8'hAA*/~data_i;


  
  
initial                                                
begin
  n_rst = 1;
  clk = 0;
  miso = 0;
  data_i = {8{1'bx}};
  have_data = 0;
  
  #1000
  
  have_data = 1;
  data_i <= 8'h55/*AA*/;
  
  #5040
  have_data = 0;

  #3000
  
  $display("Testbench end");
  $stop;
end


endmodule

