`timescale 1 ms/ 1 ms

module spi_master_byte #(
  parameter [0:0] CPOL = 0,
  parameter [0:0] CPHA = 0,
  parameter [7:0] BYTES_PER_FRAME = 2,
  parameter [2:0] PAUSE = 7,
  parameter [0:0] BIDIR = 1,
  parameter [7:0] SWAP_DIR_BIT_NUM = 7
)(
  input n_rst,
  
  input sclk,
  input miso,
  output mosi,
  output reg n_cs,
  inout sdio,
  output io_update,
  
  input [7:0] master_data,
  input master_empty,
  output reg master_rdreq,
  
  output reg [7:0] miso_reg,
  output reg slave_wrreq
);


wire mosi_int;
wire miso_int;

reg [7:0] mosi_reg;
assign mosi_int = mosi_reg[7];
reg [2:0] bit_cnt;
reg [7:0] byte_cnt;
reg [2:0] pause_cnt;

wire load_condition = n_cs ? !(master_empty | (pause_cnt != (PAUSE - 3'd1))) : &bit_cnt & !((byte_cnt == BYTES_PER_FRAME - 8'd1) | master_empty);
wire eoframe_condition = &bit_cnt & ((byte_cnt == BYTES_PER_FRAME - 8'd1) | master_empty);


generate
  if(CPOL)    
    always@(posedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        bit_cnt <= 0;
        n_cs <= 1;
        master_rdreq <= 0;
        byte_cnt <= 0;
        mosi_reg <= 0;
        pause_cnt <= 0;
        end
      else
        begin
        if(n_cs)
          begin
          n_cs <= master_empty | (pause_cnt != (PAUSE - 3'd1));
          bit_cnt <= 0;
          byte_cnt <= 0;
          end
        else
          begin
          n_cs <= eoframe_condition;
          bit_cnt <= bit_cnt + 1'b1;
          if(&bit_cnt)
            byte_cnt <= byte_cnt + 1'b1;
          end
        
        master_rdreq <= load_condition;
        
        if(load_condition)
          mosi_reg <= master_data;
        else
          mosi_reg <= mosi_reg << 1;
          
        if(eoframe_condition)
          pause_cnt <= 0;
        else if(pause_cnt != (PAUSE - 3'd1))
          pause_cnt <= pause_cnt + 1'b1;
        end
  else
    always@(negedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        bit_cnt <= 0;
        n_cs <= 1;
        master_rdreq <= 0;
        byte_cnt <= 0;
        mosi_reg <= 0;
        pause_cnt <= 0;
        end
      else
        begin
        if(n_cs)
          begin
          n_cs <= master_empty | (pause_cnt != (PAUSE - 3'd1));
          bit_cnt <= 0;
          byte_cnt <= 0;
          end
        else
          begin
          n_cs <= eoframe_condition;
          bit_cnt <= bit_cnt + 1'b1;
          if(&bit_cnt)
            byte_cnt <= byte_cnt + 1'b1;
          end
        
        master_rdreq <= load_condition;
        
        if(load_condition)
          mosi_reg <= master_data;
        else
          mosi_reg <= mosi_reg << 1;
          
        if(eoframe_condition)
          pause_cnt <= 0;
        else if(pause_cnt != (PAUSE - 3'd1))
          pause_cnt <= pause_cnt + 1'b1;
        end
endgenerate



generate
  if(CPHA)
    always@(negedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        miso_reg <= 0;
        slave_wrreq <= 0;
        end
      else
        begin
        if(!n_cs)
          begin
          miso_reg[0] <= miso_int;
          miso_reg[7:1] <= miso_reg[6:0];
          end
        
        slave_wrreq <= !n_cs & &bit_cnt;
        end
  else
    always@(posedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        miso_reg <= 0;
        slave_wrreq <= 0;
        end
      else
        begin
        if(!n_cs)
          begin
          miso_reg[0] <= miso_int;
          miso_reg[7:1] <= miso_reg[6:0];
          end
        
        slave_wrreq <= !n_cs & &bit_cnt;
        end
endgenerate



generate
  if(BIDIR)
    begin
    reg read;
    reg [7:0] z_cnt;
    reg io_update_reg;
    wire high_z = read & (z_cnt > SWAP_DIR_BIT_NUM);
   
    assign sdio = high_z ? 1'bz : mosi_int;
    assign miso_int = sdio;
    assign mosi = 0;
    assign io_update = io_update_reg;

    if(CPOL)
      always@(posedge sclk or negedge n_rst)
        if(!n_rst)
          begin
          z_cnt <= 0;
          read <= 0;
          io_update_reg <= 0;
          end
        else
          if(n_cs)
            begin
            z_cnt <= 0;
            read <= 0;
            io_update_reg <= 0;
            end
          else
            begin
            z_cnt <= z_cnt + 1'b1;
            io_update_reg <= eoframe_condition & !read;
            if(~|z_cnt)
              read <= mosi_int;
            end
    else
      always@(negedge sclk or negedge n_rst)
        if(!n_rst)
          begin
          z_cnt <= 0;
          read <= 0;
          io_update_reg <= 0;
          end
        else
          if(n_cs)
            begin
            z_cnt <= 0;
            read <= 0;
            io_update_reg <= 0;
            end
          else
            begin
            z_cnt <= z_cnt + 1'b1;
            io_update_reg <= eoframe_condition & !read;
            if(~|z_cnt)
              read <= mosi_int;
            end
    end
  else
    begin
    assign mosi = mosi_int;
    assign miso_int = miso;
    assign io_update = 0;
    end
endgenerate



endmodule