module func_testing
(
  // internal and system
  input       n_rst,
  input       sys_clk,
  input       dds_clk,
  input [7:0] master_data,
  input [4:0] valid_bus,        // 4 = video samples
  input [4:0] rdreq_bus,        // 3 = (start / stop) and (CCD mode / plain ADC mode)
  output [4:0] have_msg_bus,    // 2 = black level value in CCD mode
  output [7:0] slave_data,      // 1 = HD and VD
  output reg   video_in_select, // 0 = parall or serial output
  // connect with DAC
  output reg [13:0] dac_d,
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
  output [2:0]  my_counter,
  output my_master_empty
);




reg [15:0] black_level;
always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    begin
    video_in_select <= 0;
    hd_fpga         <= 0;
    vd_fpga         <= 0;
    black_level     <= 0;
    end
  else
    begin
    if(valid_bus[0])  video_in_select  <= master_data[0];
    if(valid_bus[1])  begin
                      hd_fpga          <= master_data[1];
                      vd_fpga          <= master_data[0];
                      end
    if(valid_bus[2])  begin
                      black_level[7:0] <= black_level[15:8];  // if lsb comes first
                      black_level[15:8] <= master_data;
                      end
    end




wire ctrl_ena; assign ctrl_ena = valid_bus[3];
wire samples_ena; assign samples_ena = valid_bus[4];
reg ccd_or_plain;
wire [15:0] master_q;
wire master_empty;
wire slave_empty;
reg [1:0] state;
localparam [1:0] IDLE       = 2'h0;   // WR = write to RAM; RD = read from RAM
localparam [1:0] WR_FROM_PC = 2'h1;
localparam [1:0] RD_TO_DAC  = 2'h2;   // or WR_FROM_BOS
localparam [1:0] RD_TO_PC   = 2'h3;
reg [2:0] inner_cnt;  // counts from 0 to 7

always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    begin
    state <= IDLE;
    ccd_or_plain <= 0;
    end
  else
    case(state)
    IDLE:
      begin
      if(ctrl_ena & (master_data[7:4] == 4'hA))    // start
        begin
        state <= WR_FROM_PC;
        ccd_or_plain <= master_data[0];
        end
      end
    WR_FROM_PC:
      begin
      if(ctrl_ena & (master_data == 8'h55))    // stop
        state <= RD_TO_DAC;
      end
    RD_TO_DAC:
      begin
      if(master_empty & (inner_cnt == 3'd0))
        state <= RD_TO_PC;
      end
    RD_TO_PC:
      if(slave_empty)
        state <= IDLE;
    default:
      begin
      state <= IDLE;
      end
    endcase


reg master_rdreq;

always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    begin
    inner_cnt <= 0;
    master_rdreq <= 0;
    dac_d <= 0;
    shp_fpga <= 0;
    shd_fpga <= 0;
    clk_fpga <= 0;
    end
  else
    begin
    if(state == RD_TO_DAC)
      begin
      inner_cnt <= inner_cnt + 1'b1;
      master_rdreq <= (inner_cnt == 3'd7) & (!master_empty);
      
      if(inner_cnt == 3'd0)
        clk_fpga <= 1;
      else if(inner_cnt == 3'd4)
        clk_fpga <= 0;
        
      if(ccd_or_plain)
        dac_d <= master_q;
      else
        begin
        if(inner_cnt == 3'd0)
          dac_d <= black_level;
        else if(inner_cnt == 3'd4)
          dac_d <= master_q;
        end
      
      if(inner_cnt == 3'd1)
        shp_fpga <= 0;
      else if(inner_cnt == 3'd3)
        shp_fpga <= 1;
      
      if(inner_cnt == 3'd5)
        shd_fpga <= 0;
      else if(inner_cnt == 3'd7)
        shd_fpga <= 1;

      end
    else
      begin
      inner_cnt <= 0;
      shp_fpga <= 1;
      shd_fpga <= 1;
      clk_fpga <= 1;
      end

    end






wire master_wrreq;
assign master_wrreq = samples_ena & (state == WR_FROM_PC);
wire [7:0] used;

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
	.wrclk(/*sys_clk*/dds_clk),
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



assign have_msg_bus[0] = 1'b0;
assign have_msg_bus[1] = 1'b0;
assign have_msg_bus[2] = 1'b0;
assign have_msg_bus[3] = 1'b0;
assign have_msg_bus[4] = !slave_empty & (state == RD_TO_PC);

// DEBUG ASSIGNS
assign my_state = state;
assign my_m_wrreq = master_wrreq;
assign my_m_used = used;
assign my_m_rdreq = master_rdreq;
assign my_m_q = master_q;
assign my_counter = inner_cnt;
assign my_master_empty = master_empty;


endmodule