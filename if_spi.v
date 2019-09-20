module if_spi #(parameter CPOL = 0)
(
  input n_rst,
  input clk,
  
  output  n_cs,
  output  sclk,
  output  mosi,
  input   miso,
  
  input [7:0] in_data,
  input       in_ena,
  
  input         enc_rdreq,
  output [7:0]  out_data,
  output        have_msg,
  output [7:0]  len
);

wire rst_internal = !n_rst | m_full | s_full;

spi_master_byte #(.CLK_DIV_EVEN(8), .CPOL(CPOL)) spi_master_inst
(
  .sclk     (sclk),
  .n_cs     (n_cs),
  .mosi     (mosi),
  .miso     (miso),
  
  .n_rst    (!rst_internal),
  .clk      (clk),
  
  .empty    (m_empty),
  .data_i   (m_dout),
  .rdreq    (m_rdreq),
  
  .miso_reg (s_din),
  .wrreq    (s_wrreq)
);
wire [7:0] s_din;
wire s_wrreq;


sc_fifo fifo_master
(
  .aclr (rst_internal),
  .clock(clk),
  .data (in_data),
  .rdreq(m_rdreq),
  .wrreq(in_ena),
  .empty(m_empty),
  .full (m_full),
  .q    (m_dout)
);
wire m_empty;
wire [7:0] m_dout;
wire m_rdreq;
wire m_full;

sc_fifo fifo_slave
(
  .aclr (rst_internal),
  .clock(clk),
  .data (s_din),
  .rdreq(enc_rdreq),
  .wrreq(s_wrreq),
  .empty(s_empty),
  .full (s_full),
  .q    (out_data),
  .usedw(used)
);
wire s_empty;
wire s_full;
assign have_msg = !s_empty;
wire [5:0] used;
assign len = {2'b00, used};
  
endmodule