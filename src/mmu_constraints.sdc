# ====================================================================
# Synopsys Design Constraints (SDC) - Production Tapeout Specification
# Target: 85.91 MHz Operation Master Crystal Multiplier)
# ====================================================================

# 1. Hardcode the Clock Period directly to 11.64ns to prevent Tcl parsing bugs
create_clock -name clk -period 11.6400 [get_ports clk]

# 2. Add a Strict 250-Picosecond Guard Band to Protect Against Clock Jitter & PCB Noise
set_clock_uncertainty 0.2500 [get_clocks clk]

# 3. Handle Logically Exclusive Paths Across the Test Multiplexer Matrix
# Prevents the router from checking cross-talk on overlapping mux tracks
set_clock_groups -logically_exclusive \
    -group [get_clocks clk] \
    -group [get_clocks sys_clk]

# 4. Safe Asynchronous Clock Grouping
# Disables multi-nanosecond CDC path tracking between distinct domains
set_clock_groups -asynchronous \
    -group [get_clocks clk] \
    -group [get_clocks sys_clk]

# ====================================================================
# 5. Explicit Peripheral I/O Boundaries (Essential for Tester Pin Stability)
# ====================================================================

# Enforce realistic 2.0ns delay thresholds explicitly on the exact target ports
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports ui_in]
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports uio_in]

set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uo_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_oe]

# 6. Constrain Output Drive Loads (Match Tiny Tapeout Pad Ring Capacitance)
set_load 0.0334 [get_ports uo_out]
set_load 0.0334 [get_ports uio_out]
set_load 0.0334 [get_ports uio_oe]
