create_clock -period 50MHz [get_ports fpga_clk_48]

#derive_pll_clocks

derive_clock_uncertainty
