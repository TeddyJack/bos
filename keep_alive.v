module keep_alive (
  input       n_rst,
  input       clk,
  input [7:0] data,
  input       ena,
  
  output reg    have_msg,
  input         rdreq,
  output [7:0]  data_out,
  output [7:0]  len
);

assign data_out = 8'hEA;
assign len = 8'h1;

always@(posedge clk or negedge n_rst)
  if(!n_rst)
    have_msg <= 1'b0;
  else
    begin
    if(rdreq)
      have_msg <= 1'b0;
    else if(ena)
      begin
      if(data == 8'hAE)
        have_msg <= 1'b1;
      end
    end

endmodule