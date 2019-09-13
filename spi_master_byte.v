module spi_master_byte #(CLK_DIV_EVEN = 8)
(
  output reg sclk,
  output reg cs_n,
  output     mosi,
  input      miso,
  output reg io_update,
  
  input       rst,
  input       clk,
  input       have_data,
  input [7:0] data_i,
  output reg  rdreq,
  
  output reg [7:0] miso_reg,
  output reg       wrreq,
  
  // debug
  output my_ena,
  output my_state,
  output [2:0] my_cnt_bit,
  output [7:0] my_mosi_reg,
  output my_load_cond
  
);
assign my_ena = ena;
assign my_state = state;
assign my_cnt_bit = cnt_bit;
assign my_mosi_reg = mosi_reg;
assign my_load_cond = load_cond;




reg [7:0] mosi_reg;
assign mosi = mosi_reg[7];

localparam [7:0] QUARTER = CLK_DIV_EVEN[7:0] / 8'd4;
localparam [7:0] THREEQRTRS = QUARTER + CLK_DIV_EVEN[7:0] / 8'd2;


reg ena;
reg [7:0] cnt_ena;

always@(posedge clk or negedge rst)
  if(!rst)
    begin
    ena <= 0;
    cnt_ena <= 0;
    end
  else
    begin
    if(cnt_ena < (CLK_DIV_EVEN - 1))
      begin
      cnt_ena <= cnt_ena + 1'b1;
      ena <= 0;
      end
    else
      begin
      cnt_ena <= 0;
      ena <= 1;
      end
    end

    
always@(posedge clk or negedge rst)
  if(!rst)
    sclk <= 0;
  else if(!cs_n | io_update)
    begin
    if((cnt_ena == QUARTER) | (cnt_ena == THREEQRTRS))
      sclk <= ~sclk;
    end
  else
    sclk <= 0;



reg state;
reg [2:0] cnt_bit;
localparam IDLE  = 1'b0;
localparam SHIFT = 1'b1;
    
always@(posedge clk or negedge rst)
  if(!rst)
    begin
    state <= IDLE;
    cs_n <= 1;
    io_update <= 0;
    end
  else if(ena)
    case(state)
    IDLE:
      begin
      io_update <= 0;
      if(have_data)
        begin
        state <= SHIFT;
        cs_n <= 0;
        end
      end
    SHIFT:
      begin
      if((&cnt_bit) & !have_data)
        begin
        io_update <= 1;
        cs_n <= 1;
        state <= IDLE;
        end
      end
    default:
      state <= IDLE;
    endcase
    
always@(posedge clk or negedge rst)
  if(!rst)
    begin
    rdreq <= 0;
    wrreq <= 0;
    end
  else
    begin
    rdreq <= ena & load_cond;
    wrreq <= ena & (&cnt_bit) & (state == SHIFT);
    end
// in case of read issues, wrreq should be delayed by 1 period (attach 1 extra reg)


wire load_cond = have_data & ((state == IDLE) | (&cnt_bit));
// absolutely the same load cond via "if" description
//reg load_cond;
//always@(*)
//  case(state)
//  IDLE:  load_cond = have_data;
//  SHIFT: load_cond = have_data & (&cnt_bit);
//  endcase

always@(posedge clk or negedge rst)
  if(!rst)
    begin
    mosi_reg <= 0;
    cnt_bit <= 0;
    end
  else if(ena)
    begin
    if(load_cond)
      begin
      mosi_reg <= data_i;
      cnt_bit <= 0;
      end
    else
      begin
      mosi_reg <= mosi_reg << 1;
      cnt_bit <= cnt_bit + 1'b1;
      end
    end


    
always@(posedge clk or negedge rst)
  if(!rst)
    miso_reg <= 0;
  else if(ena)
    begin
    miso_reg[0] <= miso;
    miso_reg[7:1] <= miso_reg[6:0];
    end


  
  
  
  
  
  
  
  
  
  
  
endmodule