# ====================================================================
# Synopsys Design Constraints (SDC) - Production Tapeout Specification
# Target: 80 MHz Operation with 2-Stage Asynchronous Multiplexed Sync
# ====================================================================

# 1. Hardcode the Clock Period directly to 12.5ns to prevent Tcl parsing bugs
create_clock -name clk -period 12.5000 [get_ports clk]

# 2. Inform the Layout Engine that the Clock Tree Wires Must Have Real Propagation Delay
set_propagated_clock [get_clocks {clk}]

# 3. Add a Strict 250-Picosecond Guard Band to Protect Against Clock Jitter & PCB Noise
set_clock_uncertainty 0.2500 [get_clocks {clk}]

# 4. Handle Logically Exclusive Paths Across the Test Multiplexer Matrix
# Prevents the router from checking cross-talk on overlapping mux tracks
set_clock_groups -logically_exclusive \
    -group [get_clocks {clk}] \
    -group [get_clocks {sys_clk}]

# 5. Safe Asynchronous Clock Grouping
# Disables multi-nanosecond CDC path tracking between distinct domains
set_clock_groups -asynchronous \
    -group [get_clocks {clk}] \
    -group [get_clocks {sys_clk}]

# ====================================================================
# 6. Peripheral I/O Boundaries (Essential for Tester Pin Stability)
# ====================================================================

# Assume the external PCB/Tester consumes 2.0 ns of time before data hits our input pins
set_input_delay 2.0000 -clock [get_clocks {clk}] [get_ports {ui_in[*]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] [get_ports {uio_in[*]}]

# Reserve 2.0 ns of setup time for the physical DevKit circuit to capture our outputs
set_output_delay 2.0000 -clock [get_clocks {clk}] [get_ports {uo_out[*]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] [get_ports {uio_out[*]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] [get_ports {uio_oe[*]}]

# 7. Constrain Output Drive Loads (Match Tiny Tapeout Pad Ring Capacitance)
set_load 0.0334 [get_ports {uo_out[*]}]
set_load 0.0334 [get_ports {uio_out[*]}]
set_load 0.0334 [get_ports {uio_oe[*]}]
