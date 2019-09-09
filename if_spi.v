module if_spi #(parameter D_WIDTH = 16)
(
  input n_rst,
  input clk,
  
  output  cs,
  output  sclk,
  output  mosi,
  input   miso,
  
  input [7:0] in_data,
  input       in_ena,
  input       rd_req,
  
  output [7:0]  out_data,
  output        have_msg,
  output [7:0]  len,
  
  // debug
  output               my_go,
  output               my_busy,
  output               my_empty,
  output [D_WIDTH-1:0] my_fifo_q,
  output [D_WIDTH-1:0] my_datao,
  output               my_done,
  output               my_datao_ena
);
assign my_go = go;
assign my_busy = busy;
assign my_empty = empty;
assign my_fifo_q = fifo_q;
assign my_datao = datao;
assign my_done = done;
assign my_datao_ena = datao_ena;


spi_master
#(
  .DATA_WIDTH       (D_WIDTH),
  .NUM_PORTS        (1),
  .CLK_DIVIDER_WIDTH(3),
  .SAMPLE_PHASE     (0)
)
spi_master_inst
(
  .clk        (clk),
  .resetb     (n_rst),
  .CPOL       (1'b0), 
  .CPHA       (1'b0),
  .clk_divider(3'd6),
  
  .go        (go),
  .datai     (fifo_q),
  .datao     (datao),         // output
  .busy      (busy),
  .done      (done),         // output
  
  .dout      (miso),
  .din       (mosi),
  .csb       (cs),
  .sclk      (sclk)
);
wire               busy;
wire [D_WIDTH-1:0] datao;
wire               done;


reg go;
reg datao_ena;
reg done_delayed;

always@(posedge clk or negedge n_rst)
if(!n_rst)
  begin
  go <= 0;
  datao_ena <= 0;
  done_delayed <= 0;
  end
else
  begin
  done_delayed <= done;
  go <= !(busy | empty | go);         // same as (!busy & !empty & !go)
  datao_ena <= done & !done_delayed;
  end


spi_fifo #(.SIZE(256), .WIDTH_IN(8), .WIDTH_OUT(2 ** $clog2(D_WIDTH)), .SHOW_AHEAD("OFF")) fifo_in
(
  .aclr   (!n_rst),
  .data   (in_data),
  .rdclk  (clk),
  .rdreq  (go),
  .wrclk  (clk),
  .wrreq  (in_ena),
  .q      (fifo_q),
  .rdempty(empty),
  .rdusedw(),
  .wrfull ()
);

wire [D_WIDTH-1:0] fifo_q;
wire               empty;

spi_fifo #(.SIZE(128), .WIDTH_IN(2 ** $clog2(D_WIDTH)), .WIDTH_OUT(8), .SHOW_AHEAD("OFF")) fifo_out
(
  .aclr   (!n_rst),
  .data   (datao),
  .rdclk  (clk),
  .rdreq  (rd_req),
  .wrclk  (clk),
  .wrreq  (datao_ena),
  .q      (out_data),
  .rdempty(out_empty),
  .rdusedw(len),
  .wrfull ()
);
wire out_empty;
assign have_msg = !out_empty;
  
  
endmodule