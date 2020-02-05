module if_spi_multi
#(
  parameter N_SLAVES = 3,
  parameter CPOL = 0,
  parameter CPHA = 0
)
(
  input                     n_rst,
  input                     clk,

  output                    sclk,
  output                    mosi,
  input                     miso,
  output  [1*N_SLAVES-1:0]  n_cs_bus,
  
  input   [7:0]             m_din,
  input   [1*N_SLAVES-1:0]  m_wrreq_bus,
  
  output  [8*N_SLAVES-1:0]  s_dout_bus,
  output  [8*N_SLAVES-1:0]  len_bus,
  output  [1*N_SLAVES-1:0]  have_msg_bus,
  input   [1*N_SLAVES-1:0]  s_rdreq_bus
);



reg [$clog2(N_SLAVES)-1:0] select;

wire [7:0]            m_dout_bus [N_SLAVES-1:0];
wire [1*N_SLAVES-1:0] m_empty_bus;
wire [1*N_SLAVES-1:0] m_rdreq_bus;
wire ready;

wire [7:0]            s_din;
wire [1*N_SLAVES-1:0] s_wrreq_bus;
wire [1*N_SLAVES-1:0] s_empty_bus;

wire m_rdreq;
wire s_wrreq;
wire n_cs;


// multiplexers
wire [7:0] m_dout = m_dout_bus[select];
wire       m_empty = m_empty_bus[select];
// demultiplexers
assign m_rdreq_bus = m_rdreq << select;
assign s_wrreq_bus = s_wrreq << select;
assign n_cs_bus = (n_cs << select) | (~(1'b1 << select));

assign have_msg_bus = ~s_empty_bus;



spi_master_byte #(.CLK_DIV_EVEN(8), .CPOL(CPOL), .CPHA(CPHA)) spi_master_inst
(
  .sclk     (sclk),
  .n_cs     (n_cs),
  .mosi     (mosi),
  .miso     (miso),
  
  .n_rst    (n_rst),
  .clk      (clk),
  
  .empty    (m_empty),
  .data_i   (m_dout),
  .rdreq    (m_rdreq),
  
  .miso_reg (s_din),
  .wrreq    (s_wrreq),
  
  .ready    (ready)
);



always@(posedge clk or negedge n_rst)
if(!n_rst)
  select <= 0;
else
  begin
  if(m_empty & ready)
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
  sc_fifo fifo_master
  (
    .aclr (!n_rst),
    .clock(clk),
    .data (m_din),
    .rdreq(m_rdreq_bus[i]),
    .wrreq(m_wrreq_bus[i]),
    .empty(m_empty_bus[i]),
    .full (),
    .q    (m_dout_bus[i])
  );
  
  sc_fifo fifo_slave
  (
    .aclr (!n_rst),
    .clock(clk),
    .data (s_din),
    .rdreq(s_rdreq_bus[i]),
    .wrreq(s_wrreq_bus[i]),
    .empty(s_empty_bus[i]),
    .full (),
    .q    (s_dout_bus[8*i+:8]),
    .usedw(len_bus[8*i+:6])
  );
  
  assign len_bus[(8*i+6)+:2] = 2'b00; // fill with zeros
  end
endgenerate



endmodule