`include "defines.v"

module cmd_encoder (
  input                 n_rst,
  input                 clk,
  
  input  [1*`N_SRC-1:0] have_msg_bus,
  input  [8*`N_SRC-1:0] data_bus,
  input  [8*`N_SRC-1:0] len_bus,
  output [1*`N_SRC-1:0] rdreq_bus,
  
  output reg [7:0]      tx_data,
  output reg            tx_valid,
  input                 tx_ready
);



reg [7:0] current_len;
reg [($clog2(`N_SRC)-1):0] current_source;
wire [7:0] current_data = data_bus[8*current_source+:8];

reg [2:0] state;
localparam [2:0] IDLE         = 0;
localparam [2:0] SEND_PREFIX  = 1;
localparam [2:0] SEND_SOURCE  = 2;
localparam [2:0] SEND_LEN     = 3;
localparam [2:0] SEND_DATA    = 4;
localparam [2:0] SEND_CRC     = 5;

reg [7:0] cnt;
reg [7:0] crc;
reg rdreq;
assign rdreq_bus = rdreq << current_source;

wire transition_cond = tx_ready & !tx_valid & ((state != IDLE) | have_msg_bus[current_source]);


always@(posedge clk or negedge n_rst)
  if(!n_rst)
    begin
    state <= IDLE;
    current_source <= 0;
    cnt <= 0;
    tx_valid <= 0;
    crc <= 0;
    current_len <= 0;
    rdreq <= 0;
    tx_data <= 0;
    end
  else
    begin
    tx_valid <= transition_cond & (state != SEND_CRC);
    //rdreq <= tx_valid & ((state == SEND_LEN) | (state == SEND_DATA)) & (cnt < current_len); // normal
    rdreq <= tx_valid & (state == SEND_DATA) & (cnt <= current_len); // show ahead
    
    if((state == IDLE) & !transition_cond)
      begin
      if(current_source < (`N_SRC-1))
        current_source <= current_source + 1'b1;
      else
        current_source <= 0;
      end
    
    if(transition_cond)
      case(state)
      IDLE:
        begin
        state <= SEND_PREFIX;
        tx_data <= `PREFIX;
        end
      SEND_PREFIX:
        begin
        state <= SEND_SOURCE;
        tx_data <= current_source;
        end
      SEND_SOURCE:
        begin
        state <= SEND_LEN;
        tx_data <= len_bus[8*current_source+:8];
        current_len <= len_bus[8*current_source+:8];
        end
      SEND_LEN:
        begin
        state <= SEND_DATA;
        tx_data <= current_data;
        cnt <= cnt + 1'b1;        // difference
        crc <= current_data + current_len + current_source;
        end
      SEND_DATA:
        if(cnt < current_len)
          begin
          tx_data <= current_data;
          cnt <= cnt + 1'b1;
          crc <= crc + current_data;
          end
        else
          begin
          state <= SEND_CRC;
          tx_data <= crc;
          cnt <= 0;
          crc <= 0;
          end
      SEND_CRC:
        state <= IDLE;
      default:
        state <= IDLE;
      endcase
    end

  
endmodule