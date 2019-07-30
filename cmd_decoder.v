`include "defines.v"

module cmd_decoder(
input       clk,
input [7:0] rx_data,
input       rx_valid,
output      rx_ready,

input  [4:0]     ready_bus,
output [5*8-1:0] data_bus,
output [4:0]     valid_bus,

// debug
output [2:0] my_state,
output [7:0] my_dest,
output [7:0] my_len,
output [7:0] my_cnt
);
assign my_state = state;
assign my_dest = dest;
assign my_len = len;
assign my_cnt = cnt;
wire rst = 1;


assign rx_ready = 1;

assign valid_bus = (rx_valid & (state == READ_DATA)) << dest; // WRONG
assign data_bus = q << dest*8;


reg [7:0] dest;
reg [7:0] len;
reg [7:0] cnt;
reg [7:0] crc_calcked;
reg       crc_ok;
reg       clear;

reg [2:0] state;
localparam READ_PREFIX  = 0;
localparam READ_AST     = 1;
localparam READ_DEST    = 2;
localparam READ_LEN     = 3;
localparam READ_DATA    = 4;
localparam READ_CRC     = 5;
localparam FORWARD_DATA = 6;

always@(posedge clk or negedge rst or posedge rst_timeout)
  begin
  if(!rst | rst_timeout)
    begin
    state <= READ_PREFIX;
    dest <= 0;
    len <= 0;
    cnt <= 0;
    crc_ok <= 0;
    crc_calcked <= 0;
    end
  else
    begin
    if(rx_valid)
      case(state)
        READ_PREFIX:
          begin
          clear <= 0;
          if(rx_data == `PREFIX)
            state <= READ_AST;
          end
        READ_AST:
          if(rx_data == `ADDR_AST)
            state <= READ_DEST;
          else
            state <= READ_PREFIX;
        READ_DEST:
          begin
          dest <= rx_data;
          state <= READ_LEN;
          end
        READ_LEN:
          begin
          len <= rx_data;
          state <= READ_DATA;
          end
        READ_DATA:
          begin
          if(cnt < (len - 1'b1))
            begin
            crc_calcked <= crc_calcked + rx_data;
            cnt <= cnt + 1'b1;
            end
          else
            begin
            cnt <= 0;
            state <= READ_CRC;
            end
          end
        READ_CRC:
          begin
          crc_calcked <= 0;
          if(crc_calcked == rx_data)
            begin
            crc_ok <= 1;
            state <= FORWARD_DATA;
            end
          else
            begin
            state <= READ_PREFIX;
            clear <= 1;
            end
          end
        FORWARD_DATA:
          begin
          if(empty)
            state <= READ_PREFIX;
          end
      endcase
    end
  end

  
localparam [31:0] CNT_LIMIT = 48000000 * `TIMEOUT_MSG / 1000 - 1;   // ignore message about constant overflow
  
reg [31:0] cnt_timeout;
  
always@(posedge clk or negedge rst)
  begin
  if(!rst)
    begin
    end
  else
    begin
    if(rx_valid | (state == READ_PREFIX) | (cnt_timeout == CNT_LIMIT))
      cnt_timeout <= 0;
    else
      cnt_timeout <= cnt_timeout + 1'b1;
      
    end
  end
  
wire rst_timeout = (cnt_timeout == CNT_LIMIT);

fifo_dc fifo_dc
(
  .clock(clk),
  .data (rx_data),
  .rdreq(),
  .sclr (clear),
  .wrreq(rx_valid),
  .empty(empty),
  .full (),
  .q    (q)
);
wire empty;
wire [7:0] q;


endmodule