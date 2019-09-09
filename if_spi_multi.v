module if_spi_multi #(parameter N_SLAVES = 3)
(
  input                     clk,
  input                     n_rst,

  output                    sclk,
  output                    mosi,
  input                     miso,
  output  [1*N_SLAVES-1:0]  n_cs_bus,
  
  input   [7:0]             m_din,
  input   [1*N_SLAVES-1:0]  m_wrreq,
  
  output  [8*N_SLAVES-1:0]  s_dout,
  output  [8*N_SLAVES-1:0]  len,
  output  [1*N_SLAVES-1:0]  have_msg,
  input   [1*N_SLAVES-1:0]  s_rdreq,
  // debug
  output [$clog2(N_SLAVES)-1:0] my_select,
  output [15:0]                 my_m_dout,
  output [1*N_SLAVES-1:0]       my_m_rdreq,
  output [1*N_SLAVES-1:0]       my_m_empty,
  output [15:0]                 my_s_din,
  output [1*N_SLAVES-1:0]       my_s_wrreq,
  output                        my_busy,
  output                        my_cur_m_empty,
  output                        my_go
);
assign my_select = select;
assign my_m_dout = m_dout[1];
assign my_m_rdreq = m_rdreq;
assign my_m_empty = m_empty;
assign my_s_din = s_din;
assign my_s_wrreq = s_wrreq;
assign my_busy = busy;
assign my_cur_m_empty = cur_m_empty;
assign my_go = go;

reg [$clog2(N_SLAVES)-1:0] select;

wire [15:0]           m_dout [N_SLAVES-1:0];
wire [1*N_SLAVES-1:0] m_rdreq;
wire [1*N_SLAVES-1:0] m_empty;

wire [15:0]           s_din;
wire [1*N_SLAVES-1:0] s_wrreq;

assign n_cs_bus = n_cs << select;



spi_master
#(
  .DATA_WIDTH       (16),
  .NUM_PORTS        (1),
  .CLK_DIVIDER_WIDTH(8),
  .SAMPLE_PHASE     (0)
)
spi_master_inst
(
  .clk        (clk),
  .resetb     (n_rst),
  .CPOL       (0), 
  .CPHA       (0),
  .clk_divider(6),
  
  .go        (go),
  .datai     (cur_m_dout),
  .datao     (s_din),    // output
  .busy      (busy),
  .done      (done),         // output
  
  .dout      (miso),
  .din       (mosi),
  .csb       (n_cs),
  .sclk      (sclk)
);
wire        busy;
wire        done;
wire        n_cs;


reg go;
reg datao_ena;
reg done_delayed;

always@(posedge clk or negedge n_rst)
if(!n_rst)
  begin
  go <= 0;
  datao_ena <= 0;
  done_delayed <= 0;
  select <= 0;
  end
else
  begin
  done_delayed <= done;
  go <= !(busy | cur_m_empty | go);         // same as (!busy & !cur_m_empty & !go)
  datao_ena <= done & !done_delayed;
  if(cur_m_empty & !busy)
    begin
    if(select < (N_SLAVES-1'b1))
      select <= select + 1'b1;
    else
      select <= 0;
    end
  end

  
  
  
genvar i;
generate for(i=0; i<N_SLAVES; i=i+1)
  begin: gen
  spi_fifo #(.SIZE(256), .WIDTH_IN(8), .WIDTH_OUT(16), .SHOW_AHEAD("OFF")) fifo_master
  (
    .aclr   (!n_rst),
    .data   (m_din),
    .rdclk  (clk),
    .rdreq  (m_rdreq[i]),
    .wrclk  (clk),
    .wrreq  (m_wrreq[i]),
    .q      (m_dout[i]),
    .rdempty(m_empty[i]),
    .rdusedw(),
    .wrfull ()
  );

  spi_fifo #(.SIZE(128), .WIDTH_IN(16), .WIDTH_OUT(8), .SHOW_AHEAD("OFF")) fifo_slave
  (
    .aclr   (!n_rst),
    .data   (s_din),
    .rdclk  (clk),
    .rdreq  (s_rdreq[i]),
    .wrclk  (clk),
    .wrreq  (s_wrreq[i]),
    .q      (s_dout[8*i+:8]),
    .rdempty(s_empty[i]),
    .rdusedw(len[8*i+:8]),
    .wrfull ()
  );
  end
endgenerate

  
wire [1*N_SLAVES-1:0] s_empty;
assign have_msg = ~s_empty;
assign m_rdreq = go << select;
assign s_wrreq = datao_ena << select;
wire cur_m_empty = m_empty[select];
wire [15:0] cur_m_dout = m_dout[select];


endmodule