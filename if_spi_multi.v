module if_spi_multi #(
  parameter       N_SLAVES = 3,
  parameter [0:0] CPOL = 0,
  parameter [0:0] CPHA = 0,
  parameter [7:0] BYTES_PER_FRAME = 2,
  parameter       FIFO_SIZE = 64,
  parameter       USE_M9K = "ON",
  parameter [0:0] BIDIR = 0,
  parameter [7:0] SWAP_DIR_BIT_NUM = 7,
  parameter [0:0] SCLK_CONST = 0
)(
  input                     n_rst,
  input                     sys_clk,
  input                     sclk_common,

  output  [1*N_SLAVES-1:0]  n_cs_bus,
  output                    sclk,
  output                    mosi,
  input                     miso,
  input                     sdio,
  output                    io_update,
  
  input   [7:0]             m_din,
  input   [1*N_SLAVES-1:0]  m_wrreq_bus,
  
  input   [1*N_SLAVES-1:0]  s_rdreq_bus,
  output  [8*N_SLAVES-1:0]  s_dout_bus,
  output  [1*N_SLAVES-1:0]  have_msg_bus,
  output  [8*N_SLAVES-1:0]  len_bus
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
  .mosi         (mosi),
  .miso         (miso),
  .n_cs         (n_cs),
  .sdio         (sdio),
  .io_update    (io_update),
  .master_data  (m_dout),
  .master_empty (m_empty),
  .master_rdreq (m_rdreq),
  .miso_reg     (s_din),
  .slave_wrreq  (s_wrreq)
);



always@(posedge sclk_common or negedge n_rst)
if(!n_rst)
  select <= 0;
else
  begin
  if(m_empty & n_cs)
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
  dc_fifo fifo_master (
    .aclr     (!n_rst),
    .data     (m_din),
    .rdclk    (sclk_common),
    .rdreq    (m_rdreq_bus[i]),
    .wrclk    (sys_clk),
    .wrreq    (m_wrreq_bus[i]),
    .q        (m_dout_bus[i]),
    .rdempty  (m_empty_bus[i])
  );
  
  dc_fifo fifo_slave (
    .aclr     (!n_rst),
    .data     (s_din),
    .rdclk    (sys_clk),
    .rdreq    (s_rdreq_bus[i]),
    .wrclk    (sclk_common),
    .wrreq    (s_wrreq_bus[i]),
    .q        (s_dout_bus[8*i+:8]),
    .rdempty  (s_empty_bus[i]),
    .rdusedw  (len_bus[8*i+:$clog2(FIFO_SIZE)])
  );
  
  assign len_bus[8*i+7:8*i+$clog2(FIFO_SIZE)] = 0; // fill with zeros
  end
endgenerate



endmodule