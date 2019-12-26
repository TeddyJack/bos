create_clock -period 32MHz [get_ports fpga_clk_48]

#derive_pll_clocks

derive_clock_uncertainty
