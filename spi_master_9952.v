module spi_master_9952 #(CLK_DIV_EVEN = 8)
(
  output reg sclk,
  output reg n_cs,
  output     mosi,
  input      miso,
  output reg io_update,
  output     high_z,
  
  input       n_rst,
  input       clk,
  input       have_data,
  input [7:0] data_i,
  output reg  rdreq,
  
  output reg [7:0] miso_reg,
  output reg       wrreq
);



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


    
reg [7:0] mosi_reg;
reg [2:0] cnt_bit;
wire load_cond = have_data & ((state == IDLE) | (&cnt_bit));
assign mosi = mosi_reg[7];
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



reg state;
localparam IDLE  = 1'b0;
localparam SHIFT = 1'b1;
always@(posedge clk or negedge n_rst)
  if(!n_rst)
    begin
    state <= IDLE;
    n_cs <= 1;
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
        n_cs <= 0;
        end
      end
    SHIFT:
      begin
      if((&cnt_bit) & !have_data)
        begin
        if(!read)
          io_update <= 1;
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


    
always@(posedge clk or negedge n_rst)
  if(!n_rst)
    miso_reg <= 0;
  else if(ena)
    begin
    miso_reg[0] <= miso;
    miso_reg[7:1] <= miso_reg[6:0];
    end

    
    
localparam [7:0] QUARTER = CLK_DIV_EVEN[7:0] / 8'd4;
localparam [7:0] THREEQRTRS = QUARTER + CLK_DIV_EVEN[7:0] / 8'd2;
always@(posedge clk or negedge n_rst)
  if(!n_rst)
    sclk <= 0;
  else if(!n_cs | io_update)
    begin
    if((cnt_ena == QUARTER) | (cnt_ena == THREEQRTRS))
      sclk <= ~sclk;
    end
  else
    sclk <= 0;



wire n_rst_z = n_rst & !n_cs;
reg [7:0] cnt_z;
reg read;
always@(posedge clk or negedge n_rst_z)
  if(!n_rst_z)
    begin
    cnt_z <= 0;
    read <= 0;
    end
  else if(ena)
    begin
    cnt_z <= cnt_z + 1'b1;
    if(cnt_z == 8'd0)
      read <= mosi;
    end
assign high_z = read & (cnt_z > 8'd7);



endmodule