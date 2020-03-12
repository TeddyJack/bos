create_clock -period 100MHz [get_ports fpga_clk_100]
#create_clock -period 4MHz [get_ports dataclk_fpga]
create_clock -period 32MHz [get_ports fpga_clk_dac]


derive_pll_clocks -create_base_clocks

derive_clock_uncertainty

set output_ports {dac_din dac_sync_n din_power sync_core_n sync_digital_n sync_vpr_digital_n}
set_output_delay -clock pll_main|altpll_component|auto_generated|pll1|clk[1] 5 [get_ports $output_ports]