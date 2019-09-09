`include "defines.v"

module cmd_decoder(
input         n_rst,
input         clk,

input [7:0]   rx_data,
input         rx_valid,
output        rx_ready,

output [7:0]  q,
output [`N_SRC-1:0]  valid_bus

// debug
//output [2:0]  my_state,
//output [7:0]  my_dest,
//output [7:0]  my_len,
//output [7:0]  my_cnt,
//output [7:0]  my_crc_calcked,
//output        my_rdreq,
//output        my_empty,
//output        my_rst_timeout,
//output [31:0] my_cnt_timeout
);
//assign my_state = state;
//assign my_dest = dest;
//assign my_len = len;
//assign my_cnt = cnt;
//assign my_crc_calcked = crc_calcked;
//assign my_rdreq = rdreq;
//assign my_empty = empty;
//assign my_rst_timeout = rst_timeout;
//assign my_cnt_timeout = cnt_timeout;


assign rx_ready = 1;  // TODO

assign valid_bus = valid << dest;


reg [7:0] dest;
reg [7:0] len;
reg [7:0] cnt;
reg [7:0] crc_calcked;
reg       clear;

reg [2:0] state;
localparam READ_PREFIX  = 0;
localparam READ_AST     = 1;
localparam READ_DEST    = 2;
localparam READ_LEN     = 3;
localparam READ_DATA    = 4;
localparam READ_CRC     = 5;
localparam FORWARD_DATA = 6;

always@(posedge clk or negedge n_rst or posedge rst_timeout)
  begin
  if(!n_rst | rst_timeout)
    begin
    state <= READ_PREFIX;
    dest <= 0;
    len <= 0;
    cnt <= 0;
    crc_calcked <= 0;
    end
  else
    begin
    if(state == FORWARD_DATA)
      begin
      if(empty)
        state <= READ_PREFIX;
      end
    else if(rx_valid)
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
          crc_calcked <= crc_calcked + rx_data;
          if(cnt < (len - 1'b1))
            cnt <= cnt + 1'b1;
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
            state <= FORWARD_DATA;
            end
          else
            begin
            state <= READ_PREFIX;
            clear <= 1;
            end
          end
        default:
          state <= READ_PREFIX;   // maybe add some actions here
      endcase
    end
  end

  
localparam [31:0] CNT_LIMIT = 50000000 * `TIMEOUT_MSG / 1000 - 1;   // ignore message about constant overflow
  
reg [31:0] cnt_timeout;
  
always@(posedge clk or negedge n_rst)
  begin
  if(!n_rst)
    cnt_timeout <= 0;
  else
    begin
    if(rx_valid | (state == READ_PREFIX) | rst_timeout)
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
  .rdreq(rdreq),
  .aclr (!n_rst),
  .sclr (clear | rst_timeout),
  .wrreq(rx_valid & (state == READ_DATA)),
  .empty(empty),
  .full (),
  .q    (q)
);
wire empty;
wire rdreq = !empty & (state == FORWARD_DATA);

reg valid;
always@(posedge clk or negedge n_rst)
  begin
  if(!n_rst)
    valid <= 0;
  else
    valid <= rdreq;
  end


endmodule