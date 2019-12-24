module func_testing
(
  // internal and system
  input       n_rst,
  input       sys_clk,
  input       dds_clk,
  input [7:0] master_data,
  input [3:0] valid_bus,
  input [3:0] rdreq_bus,
  output [3:0] have_msg_bus,
  output [7:0] slave_data,
  output reg   video_in_select,
  // connect with DAC
  output [13:0] dac_d,
  // SBIS BOS parall input
  input        dataclk_fpga,
  input [11:0] q_fpga,
  // SBIS BOS - signals related with analog video signal
  output reg  clk_fpga,
  output reg  shp_fpga,
  output reg  shd_fpga,
  output reg  hd_fpga,
  output reg  vd_fpga,
  output      clpdm_fpga,
  output      clpob_fpga,
  output      pblk_fpga,
  
  // debug
  output [1:0] my_state,
  output my_m_wrreq,
  output [7:0] my_m_used,
  output my_m_rdreq,
  output [15:0] my_m_q,
  output [2:0]  my_counter
);

assign have_msg_bus[0] = 1'b0;
assign have_msg_bus[1] = 1'b0;
assign have_msg_bus[2] = 1'b0;

reg [1:0] state;
localparam [1:0] IDLE       = 2'h0;   // WR = write to RAM; RD = read from RAM
localparam [1:0] WR_FROM_PC = 2'h1;
localparam [1:0] RD_TO_DAC  = 2'h2;   // or WR_FROM_BOS
localparam [1:0] RD_TO_PC   = 2'h3;
wire slave_empty;
assign have_msg_bus[3] = !slave_empty & (state == RD_TO_PC);

wire ctrl_ena;
assign ctrl_ena = valid_bus[2];
wire samples_ena;
assign samples_ena = valid_bus[3];

reg [31:0] cnt_samples_pc;
reg [28:0] n_samples_bos;
wire [31:0] used;

wire [15:0] master_q;
wire master_empty;
reg master_rdreq;

reg [2:0] counter;



always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    begin
    video_in_select <= 0;
    hd_fpga         <= 0;
    vd_fpga         <= 0;
    end
  else
    begin
    if(valid_bus[0]) video_in_select  <= master_data[0];
    if(valid_bus[1]) begin
                     hd_fpga          <= master_data[1];
                     vd_fpga          <= master_data[0];
                     end
    end



always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    begin
    state <= IDLE;
    cnt_samples_pc <= 0;
    counter <= 0;
    end
  else
    case(state)
    IDLE:
      begin
      if(ctrl_ena & (master_data == 8'hAA))    // make sure
        state <= WR_FROM_PC;
      end
    WR_FROM_PC:
      begin
      if(ctrl_ena & (master_data == 8'hBB))    // make sure
        begin
        state <= RD_TO_DAC;
        n_samples_bos <= used[31:3];  // make sure used is measured in q-words, not d-words
        end
      end
    RD_TO_DAC:  // everything at once
      begin
      if(master_empty) // how many bytes has been sent to DAC, make sure
        state <= RD_TO_PC;
      // master_rdreq should be generated somewhere here
      end
    RD_TO_PC:
      if(slave_empty)
        begin
        state <= IDLE;
        cnt_samples_pc <= 0;
        end
    default:
      begin
      state <= IDLE;
      end
    endcase



always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    master_rdreq <= 0;
  else
    begin
    master_rdreq <= !master_empty & (state == RD_TO_DAC);
    end


wire master_wrreq;
assign master_wrreq = samples_ena & (state == WR_FROM_PC);

fifo_trans_w #
(
  .SIZE       (512),  // less than 8 doesn't work with parametrized fifo
  .WIDTH_IN   (8),
  .WIDTH_OUT  (16),
  .SHOW_AHEAD ("ON")
)
master_fifo
(
  .aclr (!n_rst),
	.data (master_data),
	.rdclk(dds_clk),
	.rdreq(master_rdreq),
	.wrclk(sys_clk),
	.wrreq(master_wrreq),
	
  .q      (master_q),
	.rdempty(master_empty),
	.rdusedw(used),
	.wrfull ()  
);



fifo_trans_w #
(
  .SIZE       (256),  // less than 8 doesn't work with parametrized fifo
  .WIDTH_IN   (16),
  .WIDTH_OUT  (8),
  .SHOW_AHEAD ("OFF")
)
slave_fifo
(
  .aclr (!n_rst),
	.data ({4'b0, q_fpga}),
	.rdclk(sys_clk),
	.rdreq(rdreq_bus[3]),
	.wrclk(dataclk_fpga),
	.wrreq(state == RD_TO_DAC),   // be careful, state is driven by sys_clk, but expected by wrclk
	
  .q      (slave_data),
	.rdempty(slave_empty),
	.rdusedw(),
	.wrfull ()  
);


always@(posedge sys_clk or negedge !n_rst)
  if(!n_rst)
    begin
    shp_fpga <= 1;
    shd_fpga <= 1;
    clk_fpga <= 0;
    counter <= 0;
    end
  else
    begin
    if(master_rdreq)
      begin
      counter <= counter + 1'b1;
      shp_fpga <= !(counter == 3'd1);
      shd_fpga <= !(counter == 3'd5);
      if(counter == 3'd7)
        clk_fpga <= ~clk_fpga;
      end
    else
      begin
      shp_fpga <= 1;
      shd_fpga <= 1;
      clk_fpga <= 0;
      counter <= 0;
      end
    end

// DEBUG ASSIGNS
assign my_state = state;
assign my_m_wrreq = master_wrreq;
assign my_m_used = used;
assign my_m_rdreq = master_rdreq;
assign my_m_q = master_q;
assign my_counter = counter;


endmodule