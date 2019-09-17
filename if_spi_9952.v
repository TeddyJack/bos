module if_spi_9952
(
  input         n_rst,
  input         clk,
  
  output        n_cs,
  output        sclk,
  inout         sdio,
  output        io_update,
  
  input  [7:0]  in_data,
  input         in_ena,
  
  input         rd_req,
  output [7:0]  out_data,
  output        have_msg,
  output [7:0]  len
);

assign sdio = high_z ? 1'bz : mosi;
assign miso = sdio;

wire rst_internal = !n_rst | m_full | s_full;

spi_master_9952 #(.CLK_DIV_EVEN(8)) spi_master_9952_inst
(
  .sclk     (sclk),
  .n_cs     (n_cs),
  .mosi     (mosi),
  .miso     (miso),
  .io_update(io_update),
  .high_z   (high_z),
  
  .n_rst    (!rst_internal),
  .clk      (clk),
  
  .have_data(!m_empty),
  .data_i   (m_dout),
  .rdreq    (m_rdreq),
  
  .miso_reg (s_din),
  .wrreq    (s_wrreq)
);
wire high_z;
wire miso;
wire mosi;
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
  .rdreq(rd_req),
  .wrreq(s_wrreq),
  .empty(s_empty),
  .full (s_full),
  .q    (out_data),
  .usedw(len)
);
wire s_empty;
wire s_full;
assign have_msg = !s_empty;

endmodule