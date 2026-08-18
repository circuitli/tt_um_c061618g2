# Industry-standard safe asynchronous clock domain grouping
set_clock_groups -asynchronous -group [get_clocks {clk}] -group [get_clocks {sys_clk}]
