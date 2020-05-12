module fpga_regs (
  input            n_rst,
  input            clk,
  input  [7:0]     master_data,
  input  [9:0]     valid_bus,
  
  input  [9:0]     rdreq_bus,
  output [9:0]     have_msg_bus,
  output [9*8+7:0] slave_data_bus,
  output [9*8+7:0] len_bus,
  
  output reg [3:0] a,                    // address on multiplexer to select Q[i]
  output reg       load_pr_3v7,          // connects mux output with 1.65 kOhm load
  output reg       load_pdr,             // connects mux output with 240 Ohm load
  output reg       dac_gain,             // off/on analog signal attenuation
  output reg       dac_switch_out_fpga,  // differential/regular analog signal
  output reg       dac_ena_out_fpga,     // disable/enable output of analog signal
  output reg       off_pr_digital_fpga,  // off/on overvoltage to digital inputs of BOS
  output reg       functional,           // off/on level translators
  output reg       off_vcore_fpga,       // off/on v_core
  output reg       off_vdigital_fpga,    // off_on v_digital
  output reg       rst_fpga,
  output reg       stby_fpga,
  output reg       ena_clpdm
);

assign have_msg_bus = 10'b0;
assign slave_data_bus = 80'b0;
assign len_bus = 80'b0;

always@(posedge clk or negedge n_rst)
  if(!n_rst)
    begin
    a                   <= 0;
    load_pr_3v7         <= 0;
    load_pdr            <= 0;
    dac_gain            <= 0;
    dac_switch_out_fpga <= 0;
    dac_ena_out_fpga    <= 0;
    off_pr_digital_fpga <= 0;
    functional          <= 0;
    off_vcore_fpga      <= 1;
    off_vdigital_fpga   <= 1;
    rst_fpga            <= 0;
    stby_fpga           <= 0;
    ena_clpdm           <= 0;
    end
  else
    begin
    if(valid_bus[0]) a                   <= master_data[3:0];
    if(valid_bus[1]) begin
                     load_pr_3v7         <= master_data[1];
                     load_pdr            <= master_data[0];
                     end
    if(valid_bus[2]) dac_gain            <= master_data[0];
    if(valid_bus[3]) dac_switch_out_fpga <= master_data[0];
    if(valid_bus[4]) dac_ena_out_fpga    <= master_data[0];
    if(valid_bus[5]) off_pr_digital_fpga <= master_data[0];
    if(valid_bus[6]) functional          <= master_data[0];
    if(valid_bus[7]) off_vcore_fpga      <= master_data[0];
    if(valid_bus[8]) off_vdigital_fpga   <= master_data[0];
    if(valid_bus[9]) begin
                     ena_clpdm           <= master_data[2];
                     stby_fpga           <= master_data[1];
                     rst_fpga            <= master_data[0];
                     end
    end


endmodule