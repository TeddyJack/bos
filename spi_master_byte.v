// multi purpose SPI master than intended to work with two 8 bits-wide single clock FIFOs
// "master->slave" FIFO must be SHOW AHEAD type
// "slave->master" FIFO - as you wish, depends on your further logic


module spi_master_byte
#(
  parameter CLK_DIV_EVEN = 8,
  parameter CPOL = 0
)
(
  output reg sclk,
  output reg n_cs,
  output     mosi,
  input      miso,
  
  input       n_rst,
  input       clk,
  // connect to "master->slave" FIFO
  input       empty,
  input [7:0] data_i,
  output reg  rdreq,
  // connect to "slave->master" FIFO
  output reg [7:0] miso_reg,
  output reg       wrreq,
  
  output ready
);

assign ready = (state == IDLE);

reg [7:0] mosi_reg;
assign mosi = mosi_reg[7];

localparam [7:0] QUARTER = CLK_DIV_EVEN[7:0] / 8'd4;
localparam [7:0] THREEQRTRS = QUARTER + CLK_DIV_EVEN[7:0] / 8'd2;


reg ena;
reg [7:0] cnt_ena;

always@(posedge clk or negedge n_rst)
  if(!n_rst)
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

    
always@(posedge clk or negedge n_rst)
  if(!n_rst)
    sclk <= CPOL[0];
  else if(!n_cs)
    begin
    if((cnt_ena == QUARTER) | (cnt_ena == THREEQRTRS))
      sclk <= ~sclk;
    end
  else
    sclk <= CPOL[0];



reg state;
reg [2:0] cnt_bit;
localparam IDLE  = 1'b0;
localparam SHIFT = 1'b1;
    
always@(posedge clk or negedge n_rst)
  if(!n_rst)
    begin
    state <= IDLE;
    n_cs <= 1;
    end
  else if(ena)
    case(state)
    IDLE:
      begin
      if(!empty)
        begin
        state <= SHIFT;
        n_cs <= 0;
        end
      end
    SHIFT:
      begin
      if((&cnt_bit) & empty)
        begin
        n_cs <= 1;
        state <= IDLE;
        end
      end
    default:
      state <= IDLE;
    endcase
    
always@(posedge clk or negedge n_rst)
  if(!n_rst)
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


wire load_cond = !empty & ((state == IDLE) | (&cnt_bit));
// absolutely the same load_cond via "if" description
//reg load_cond;
//always@(*)
//  case(state)
//  IDLE:  load_cond = !empty;
//  SHIFT: load_cond = !empty & (&cnt_bit);
//  endcase

always@(posedge clk or negedge n_rst)
  if(!n_rst)
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


    
always@(posedge clk or negedge n_rst)
  if(!n_rst)
    miso_reg <= 0;
  else if(ena)
    begin
    miso_reg[0] <= miso;
    miso_reg[7:1] <= miso_reg[6:0];
    end
  
  
  
  
endmodule