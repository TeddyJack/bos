module if_spi #(
  parameter [0:0] CPOL = 0,
  parameter [0:0] CPHA = 0,
  parameter [7:0] BYTES_PER_FRAME = 2,
  parameter       FIFO_SIZE = 64,
  parameter       USE_M9K = "ON",
  parameter [0:0] BIDIR = 0,
  parameter [7:0] SWAP_DIR_BIT_NUM = 7,
  parameter [0:0] SCLK_CONST = 0
)(
  input n_rst,
  input sys_clk,
  input sclk_common,
  
  output  n_cs,
  output  sclk,
  output  mosi,
  input   miso,
  inout   sdio,
  output  io_update,
  
  input   [7:0] in_data,
  input         in_ena,
  
  input         enc_rdreq,
  output  [7:0] out_data,
  output        have_msg,
  output  [7:0] len
);



wire        m_empty;
wire [7:0]  m_dout;
wire        m_rdreq;
wire [7:0]  s_din;
wire        s_wrreq;
wire        s_empty;
wire [$clog2(FIFO_SIZE)-1:0]  s_used;


assign have_msg = !s_empty;
assign len[7:$clog2(FIFO_SIZE)] = 0;
assign len[$clog2(FIFO_SIZE)-1:0] = s_used;



spi_master_byte #(
  .CPOL             (CPOL),
  .CPHA             (CPHA),
  .BYTES_PER_FRAME  (BYTES_PER_FRAME),
  .BIDIR            (BIDIR),
  .SWAP_DIR_BIT_NUM (SWAP_DIR_BIT_NUM),
  .SCLK_CONST       (SCLK_CONST)
)
spi_master_inst (
  .n_rst        (n_rst),
  .sys_clk      (sclk_common),
  .sclk         (sclk),
  .miso         (miso),
  .mosi         (mosi),
  .n_cs         (n_cs),
  .sdio         (sdio),
  .io_update    (io_update),
  .master_data  (m_dout),
  .master_empty (m_empty),
  .master_rdreq (m_rdreq),
  .miso_reg     (s_din),
  .slave_wrreq  (s_wrreq)
);



dc_fifo #(
  .SIZE       (FIFO_SIZE),
  .SHOW_AHEAD ("ON"),
  .USE_M9K    (USE_M9K)
)
fifo_master (
  .aclr     (!n_rst),
  .data     (in_data),
  .rdclk    (sclk_common),
  .rdreq    (m_rdreq),
  .wrclk    (sys_clk),
  .wrreq    (in_ena),
  .q        (m_dout),
  .rdempty  (m_empty)
);



dc_fifo #(
  .SIZE       (FIFO_SIZE),
  .SHOW_AHEAD ("ON"),
  .USE_M9K    (USE_M9K)
)
fifo_slave (
  .aclr     (!n_rst),
  .data     (s_din),
  .rdclk    (sys_clk),
  .rdreq    (enc_rdreq),
  .wrclk    (sclk_common),
  .wrreq    (s_wrreq),
  .q        (out_data),
  .rdempty  (s_empty),
  .rdusedw  (s_used)
);



endmodule