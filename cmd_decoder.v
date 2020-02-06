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




reg [7:0] dest;
reg [7:0] len;
reg [7:0] cnt;
reg [7:0] crc_calcked;
reg       clear;
reg       valid;

assign valid_bus = valid << dest;

reg [2:0] state;
localparam [2:0] READ_PREFIX  = 0;
localparam [2:0] READ_DEST    = 1;
localparam [2:0] READ_LEN     = 2;
localparam [2:0] READ_DATA    = 3;
localparam [2:0] READ_CRC     = 4;
localparam [2:0] FORWARD_DATA = 5;

wire empty;
wire rdreq = !empty & (state == FORWARD_DATA);
  
reg [31:0] cnt_timeout;
localparam [31:0] CNT_LIMIT = 50000000 * `TIMEOUT_MSG / 1000 - 1;
wire rst_timeout = (cnt_timeout == CNT_LIMIT);



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
            state <= READ_DEST;
          end
        READ_DEST:
          begin
          dest <= rx_data;
          state <= READ_LEN;
          end
        READ_LEN:
          begin
          len <= rx_data;
          state <= READ_DATA;
          crc_calcked <= dest + rx_data;
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
          //if(crc_calcked == rx_data)    // comment this line to ignore crc at debugging
            begin
            state <= FORWARD_DATA;
            end
          //else
          //  begin
          //  state <= READ_PREFIX;
          //  clear <= 1;
          //  end
          end
        default:
          state <= READ_PREFIX;   // maybe add some actions here
      endcase
    end
  end



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



always@(posedge clk or negedge n_rst)
  begin
  if(!n_rst)
    valid <= 0;
  else
    valid <= rdreq;
  end


endmodule