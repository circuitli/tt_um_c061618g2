# ====================================================================
# Synopsys Design Constraints (SDC) - Production Tapeout Specification
# Target: 85.91 MHz Operation (Atari 24x Master Crystal Multiplier)
# ====================================================================

# 1. Hardcode the primary incoming clock port to 11.64ns (85.91 MHz)
create_clock -name clk -period 11.6400 [get_ports clk]

# 2. Add a 250-Picosecond Guard Band to Protect Against Clock Jitter
set_clock_uncertainty 0.2500 [get_clocks clk]

# 3. Safe Asynchronous Clock Grouping (Using Port vs Net Boundaries)
# This forces the tool to treat data crossing between the raw input 
# and your internal multiplexed structures as fully asynchronous!
set_clock_groups -asynchronous -group [get_clocks clk]

# ====================================================================
# 4. Explicit Peripheral I/O Boundaries (Referencing clk Only)
# ====================================================================
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports ui_in]
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports uio_in]

set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uo_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_oe]

# 5. Constrain Output Drive Loads (Match Tiny Tapeout Pad Ring Capacitance)
set_load 0.0334 [get_ports uo_out]
set_load 0.0334 [get_ports uio_out]
set_load 0.0334 [get_ports uio_oe]
