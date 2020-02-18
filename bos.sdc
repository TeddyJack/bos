create_clock -period 100MHz [get_ports fpga_clk_100]
create_clock -period 4MHz [get_ports dataclk_fpga]
create_clock -period 32MHz [get_ports fpga_clk_dac]


derive_pll_clocks

derive_clock_uncertainty
