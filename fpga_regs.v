module fpga_regs
(
  input              n_rst,
  input              clk,
  input  [7:0]       master_data,
  input  [20:11]     valid_bus,
  
  input  [20:11]     rdreq_bus,
  output [20:11]     have_msg_bus,
  output [21*8-1:11] slave_data_bus,
  output [21*8-1:11] len_bus,
  
  output reg         dac_gain,             // off/on analog signal attenuation
  output reg         dac_switch_out_fpga,  // differential/regular analog signal
  output reg         dac_ena_out_fpga,     // disable/enable output of analog signal
  output reg [3:0]   a,                    // address on multiplexer to select Q[i]
  output reg         load_pr_3v7,          // connects mux output with 1.65 kOhm load
  output reg         load_pdr,             // connects mux output with 240 Ohm load
  output reg         off_pr_digital_fpga,  // off/on overvoltage to digital inputs of BOS
  output reg         off_vcore_fpga,       // off/on v_core
  output reg         off_vdigital_fpga,    // off_on v_digital
  output reg         functional,           // off/on level translators

  output reg         video_in_select       // 0 = parallel, 1 = serial
);



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
    video_in_select     <= 0;
    off_vcore_fpga      <= 0;
    off_vdigital_fpga   <= 0;
    end
  else
    begin
    if(valid_bus[11]) a                   <= master_data[3:0];
    if(valid_bus[12]) begin
                      load_pr_3v7         <= master_data[1];
                      load_pdr            <= master_data[0];
                      end
    if(valid_bus[13]) dac_gain            <= master_data[0];           
    if(valid_bus[14]) dac_switch_out_fpga <= master_data[0];
    if(valid_bus[15]) dac_ena_out_fpga    <= master_data[0];
    if(valid_bus[16]) off_pr_digital_fpga <= master_data[0];
    if(valid_bus[17]) functional          <= master_data[0];
    if(valid_bus[18]) video_in_select     <= master_data[0];
    if(valid_bus[19]) off_vcore_fpga      <= master_data[0];
    if(valid_bus[20]) off_vdigital_fpga   <= master_data[0];
  
    end


endmodule