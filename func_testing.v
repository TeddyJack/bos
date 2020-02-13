// Be careful, signals, driven by "dds_clk", depend on "state", that is driven by "sys_clk". Probably should reclock "state"

`include "defines.v"

module func_testing (
  // internal and system
  input       n_rst,
  input       sys_clk,
  input       dds_clk,          // SHP, SHD etc. should be driven with dds_clk
  input [7:0] master_data,
  input [4:0] valid_bus,        // 4 = video samples
  input [4:0] rdreq_bus,        // 3 = (start / stop) and (CCD mode / plain ADC mode)
  output [4:0] have_msg_bus,    // 2 = black level value in CCD mode
  output [39:0] len_bus,        // 1 = HD and VD
  output [39:0] slave_data_bus, // 0 = parall or serial output
  output reg   video_in_select,
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
  output reg  clpdm_fpga,
  output      clpob_fpga,
  output      pblk_fpga
);




reg [23:0] local_shift_reg;
always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    begin
    video_in_select <= 0;
    hd_fpga         <= 0;
    vd_fpga         <= 0;
    local_shift_reg <= 0;
    end
  else
    begin
    if(valid_bus[0])  video_in_select  <= master_data[0];
    if(valid_bus[1])  begin
                      hd_fpga          <= master_data[1];
                      vd_fpga          <= master_data[0];
                      end
    if(valid_bus[2])  begin
                      local_shift_reg[15:0] <= local_shift_reg[23:8];  // if lsb comes first
                      local_shift_reg[23:16] <= master_data;
                      end
    end

wire [13:0] black_level;
assign black_level = local_shift_reg[13:0];
wire [8:0] num_reps_x2;
assign num_reps_x2 = {local_shift_reg[23:16],1'b0};
wire [7:0] HALF = num_reps_x2[8:1];
wire [6:0] QUARTER = num_reps_x2[8:2];
wire [5:0] ONE_EIGHTH = num_reps_x2[8:3];


wire ctrl_ena; assign ctrl_ena = valid_bus[3];
wire samples_ena; assign samples_ena = valid_bus[4];
reg ccd_or_plain;
wire [15:0] master_q;
wire master_empty;
wire slave_empty;
reg [2:0] state;
localparam [2:0] IDLE         = 3'h0;   // WR = write to RAM; RD = read from RAM
localparam [2:0] WR_FROM_PC   = 3'h1;
localparam [2:0] RD_TO_DAC    = 3'h2;   // or WR_FROM_BOS
localparam [2:0] WAIT_FOR_REQ = 3'h3;
localparam [2:0] RD_TO_PC     = 3'h4;
reg [8:0] inner_cnt;  // counts repetitions
reg [7:0] outer_cnt;  // to count samples 0 to 255
reg periodical_mode;

always@(posedge sys_clk or negedge n_rst)
  if(!n_rst)
    begin
    state <= IDLE;
    ccd_or_plain <= 0;
    periodical_mode <= 0;
    end
  else
    case(state)
    IDLE:
      begin
      if(ctrl_ena)    // start
        begin
        if(master_data[7:4] == 4'hA)
          begin
          state <= WR_FROM_PC;
          ccd_or_plain <= master_data[0];
          end
        else if(master_data == 8'hB0)
          begin
          periodical_mode <= 1;
          state <= RD_TO_DAC;
          end
        end
      end
    WR_FROM_PC:
      begin
      if(ctrl_ena & (master_data == 8'h55))    // stop
        state <= RD_TO_DAC;
      end
    RD_TO_DAC:
      begin
      if(periodical_mode)
        begin
        if(ctrl_ena & (master_data == 8'hB1))
          begin
          state <= IDLE;
          periodical_mode <= 0;
          end
        end
      else if(master_empty & (inner_cnt == 1'b0))
        state <= WAIT_FOR_REQ;
      end
    WAIT_FOR_REQ:
      if(ctrl_ena & (master_data == 8'h5A))
        state <= RD_TO_PC;
    RD_TO_PC:
      if(slave_empty)
        state <= IDLE;
    default:
      begin
      state <= IDLE;
      end
    endcase


reg master_rdreq;

always@(posedge dds_clk or negedge n_rst)
  if(!n_rst)
    begin
    inner_cnt <= 0;
    master_rdreq <= 0;
    dac_d <= 0;
    shp_fpga <= 0;
    shd_fpga <= 0;
    clk_fpga <= 0;
    outer_cnt <= 0;
    clpdm_fpga <= 0;
    end
  else
    begin
    if(state == RD_TO_DAC)
      begin
      if(inner_cnt < (num_reps_x2 - 1'b1))
        inner_cnt <= inner_cnt + 1'b1;
      else
        inner_cnt <= 0;
      
      master_rdreq <= (inner_cnt == (num_reps_x2 - 1'b1)) & (!master_empty) & (!periodical_mode);
      
      if(inner_cnt == 1'b0)
        clk_fpga <= 1;
      else if(inner_cnt == HALF)
        clk_fpga <= 0;
        
      if(ccd_or_plain)
        dac_d <= master_q[13:0];
      else
        begin
        if(inner_cnt == 1'b0)
          dac_d <= black_level[13:0];
        else if(inner_cnt == HALF)
          dac_d <= master_q[13:0];
        end
      
      if(inner_cnt == ONE_EIGHTH)
        shp_fpga <= 0;
      else if(inner_cnt == (QUARTER + ONE_EIGHTH))
        shp_fpga <= 1;
      
      if(inner_cnt == (HALF + ONE_EIGHTH))
        shd_fpga <= 0;
      else if(inner_cnt == (HALF + QUARTER + ONE_EIGHTH))
        shd_fpga <= 1;

      if(inner_cnt == 1'b0)
        outer_cnt <= outer_cnt + 1'b1;
      
      if(inner_cnt == 1'b0)
        begin
        if(outer_cnt == 1'b0)
          clpdm_fpga <= 1;
        else if((outer_cnt == 8'd246) | master_empty)    // = (256-10), where 10 is blanking len (in pixels)
          clpdm_fpga <= 0;
        end

      end
    else
      begin
      inner_cnt <= 0;
      shp_fpga <= 1;
      shd_fpga <= 1;
      clk_fpga <= 1;
      outer_cnt <= 0;
      clpdm_fpga <= 0;
      end

    end






wire master_wrreq;
assign master_wrreq = samples_ena & (state == WR_FROM_PC);
wire [$clog2(`SIZE)-1:0] used;

fifo_trans_w #(
  .SIZE       (`SIZE*2),  // less than 8 doesn't work with parametrized fifo
  .WIDTH_IN   (8),
  .WIDTH_OUT  (16),
  .SHOW_AHEAD ("ON")
)
master_fifo (
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

wire slave_rdreq; assign slave_rdreq = rdreq_bus[4];
wire [$clog2(`SIZE)-1:0] slave_used;
wire [7:0] slave_data;


fifo_trans_w #(
  .SIZE       (`SIZE),  // less than 8 doesn't work with parametrized fifo
  .WIDTH_IN   (16),
  .WIDTH_OUT  (8),
  .SHOW_AHEAD ("OFF")
)
slave_fifo (
  .aclr (!n_rst),
	.data ({4'b0000, q_fpga}),
	.rdclk(sys_clk),
	.rdreq(slave_rdreq),
	.wrclk(dataclk_fpga),
	.wrreq(state == RD_TO_DAC),   // be careful, state is driven by sys_clk, but expected by wrclk
	
  .q      (slave_data),
	.rdempty(slave_empty),
	.rdusedw(slave_used),
	.wrfull ()  
);



assign have_msg_bus[0] = 1'b0;
assign have_msg_bus[1] = 1'b0;
assign have_msg_bus[2] = 1'b0;
assign have_msg_bus[3] = 1'b0;
assign have_msg_bus[4] = !slave_empty & (state == RD_TO_PC);

assign pblk_fpga = 1'b0;
assign clpob_fpga = clpdm_fpga;

assign len_bus[39:32] = (slave_used > 8'd255) ? 8'd255 : slave_used[7:0];
assign len_bus[31:0] = 32'b0;

assign slave_data_bus[39:32] = slave_data;
assign slave_data_bus[31:0] = 32'b0;



endmodule