`timescale 1 ms/ 1 ms

module spi_master_byte #(
  parameter [0:0] CPOL = 1,
  parameter [0:0] CPHA = 0,
  parameter [7:0] BYTES_PER_FRAME = 3,
  parameter [2:0] PAUSE = 4,
  parameter [0:0] BIDIR = 1,
  parameter [7:0] SWAP_DIR_BIT_NUM = 7,   // after which bit (count from 0) high_z sets to "1"
  parameter [0:0] SCLK_CONST = 0
)(
  input n_rst,
  
  input sys_clk,
  output sclk,
  input miso,
  output mosi,
  output n_cs,
  inout sdio,
  output io_update,
  
  input [7:0] master_data,
  input master_empty,
  output reg master_rdreq,
  
  output reg [7:0] miso_reg,
  output reg slave_wrreq
);



reg [7:0] mosi_reg;
reg [2:0] bit_cnt;
reg [7:0] byte_cnt;
reg n_cs_neg; // n_cs, clocked always on negedge
reg n_cs_pha; // n_cs, clocked on edge depending (CPOL == CPHA)
wire miso_int;
wire mosi_int = mosi_reg[7];
wire load_cond = (bit_cnt == 1'b0) & !master_empty & ((n_cs_pha) | (byte_cnt != 1'b0));
wire eoframe_cond = (bit_cnt == 1'b0) & (byte_cnt == 1'b0 | master_empty);
assign n_cs = n_cs_neg & n_cs_pha;

generate
  if(SCLK_CONST)
    assign sclk = CPOL ? !sys_clk : sys_clk;
  else
    assign sclk = n_cs_neg ? CPOL : (CPOL ? !sys_clk : sys_clk);
endgenerate



always @ (negedge sys_clk or negedge n_rst)
  if (!n_rst)
    n_cs_neg <= 1;
  else
    begin
    if (n_cs_neg)
      n_cs_neg <= (bit_cnt != 1'b0) | master_empty;
    else
      n_cs_neg <= eoframe_cond;
    end



generate
  if (CPOL == CPHA)
    begin
    always @ (negedge sys_clk or negedge n_rst)
      if (!n_rst)
        begin
        bit_cnt <= PAUSE - 1'b1;
        mosi_reg <= 0;
        byte_cnt <= BYTES_PER_FRAME - 1'b1;
        master_rdreq <= 0;
        n_cs_pha <= 1;
        end
      else
        begin
        if (bit_cnt == 1'b0)
          begin
          if (n_cs_pha)
            begin
            if (!master_empty)
              begin
              n_cs_pha <= 0;
              bit_cnt <= 7;
              end
            byte_cnt <= BYTES_PER_FRAME - 1'b1;
            end
          else
            begin
            if ((byte_cnt == 1'b0) | master_empty)
              begin
              n_cs_pha <= 1;
              bit_cnt <= PAUSE - 1'b1;
              end
            else
              bit_cnt <= 7;   // or bit_cnt <= bit_cnt - 1'b1;
            byte_cnt <= byte_cnt - 1'b1;
            end
          end
        else
          bit_cnt <= bit_cnt - 1'b1;
          
        master_rdreq <= load_cond;
        
        if (load_cond)
          mosi_reg <= master_data;
        else
          mosi_reg <= mosi_reg << 1;
        end
    
    always @ (posedge sys_clk or negedge n_rst)
      if (!n_rst)
        begin
        miso_reg <= 0;
        slave_wrreq <= 0;
        end
      else
        begin
        slave_wrreq <= !n_cs_pha & (bit_cnt == 1'b0);
        if (!n_cs_pha)
          begin
          miso_reg[0] <= miso_int;
          miso_reg[7:1] <= miso_reg[6:0];
          end
        end
    end
  else
    begin
    always @ (posedge sys_clk or negedge n_rst)
      if (!n_rst)
        begin
        bit_cnt <= PAUSE - 1'b1;
        mosi_reg <= 0;
        byte_cnt <= BYTES_PER_FRAME - 1'b1;
        master_rdreq <= 0;
        n_cs_pha <= 1;
        end
      else
        begin
        if (bit_cnt == 1'b0)
          begin
          if (n_cs_pha)
            begin
            if (!master_empty)
              begin
              n_cs_pha <= 0;
              bit_cnt <= 7;
              end
            byte_cnt <= BYTES_PER_FRAME - 1'b1;
            end
          else
            begin
            if ((byte_cnt == 1'b0) | master_empty)
              begin
              n_cs_pha <= 1;
              bit_cnt <= PAUSE - 1'b1;
              end
            else
              bit_cnt <= 7;   // or bit_cnt <= bit_cnt - 1'b1;
            byte_cnt <= byte_cnt - 1'b1;
            end
          end
        else
          bit_cnt <= bit_cnt - 1'b1;
          
        master_rdreq <= load_cond;
        
        if (load_cond)
          mosi_reg <= master_data;
        else
          mosi_reg <= mosi_reg << 1;
        end
    
    always @ (negedge sys_clk or negedge n_rst)
      if (!n_rst)
        begin
        miso_reg <= 0;
        slave_wrreq <= 0;
        end
      else
        begin
        slave_wrreq <= !n_cs_pha & (bit_cnt == 1'b0);
        if (!n_cs_pha)
          begin
          miso_reg[0] <= miso_int;
          miso_reg[7:1] <= miso_reg[6:0];
          end
        end
    end
endgenerate




generate
  if (BIDIR)
    begin
    reg read;
    reg [7:0] z_cnt;
    reg io_update_reg;
    //wire high_z = read & (z_cnt > SWAP_DIR_BIT_NUM);
    reg high_z;
   
    assign sdio = high_z ? 1'bz : mosi_int;
    assign miso_int = sdio;
    assign mosi = 0;
    assign io_update = io_update_reg;

    if (CPOL == CPHA)
      always @ (negedge sys_clk or negedge n_rst)
        if (!n_rst)
          begin
          z_cnt <= 0;
          read <= 0;
          io_update_reg <= 0;
          high_z <= 0;
          end
        else
          if (n_cs_pha)
            begin
            z_cnt <= 0;
            read <= 0;
            io_update_reg <= 0;
            high_z <= 0;
            end
          else
            begin
            z_cnt <= z_cnt + 1'b1;
            io_update_reg <= eoframe_cond & !read;
            if (z_cnt == 1'b0)
              read <= mosi_int;
            if ((z_cnt == SWAP_DIR_BIT_NUM) & read)
              high_z <= 1;
            end
    else
      always @ (posedge sys_clk or negedge n_rst)
        if (!n_rst)
          begin
          z_cnt <= 0;
          read <= 0;
          io_update_reg <= 0;
          high_z <= 0;
          end
        else
          if (n_cs_pha)
            begin
            z_cnt <= 0;
            read <= 0;
            io_update_reg <= 0;
            high_z <= 0;
            end
          else
            begin
            z_cnt <= z_cnt + 1'b1;
            io_update_reg <= eoframe_cond & !read;
            if (z_cnt == 1'b0)
              read <= mosi_int;
            if ((z_cnt == SWAP_DIR_BIT_NUM) & read)
              high_z <= 1;
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