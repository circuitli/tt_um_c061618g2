# ====================================================================
# Synopsys Design Constraints (SDC) - TritonCTS Clean Production Spec
# Target: 85.91 MHz Operation (24x Master Crystal Multiplier)
# ====================================================================

# 1. Define Primary Master Clock Input Port Only (85.91 MHz)
# Removing internal clock lines prevents TritonCTS from hitting a fatal exception.
create_clock -name clk -period 11.6400 [get_ports clk]

# 2. Enforce Clock Tree Propagation Guard Band for 86 MHz Silicon Stability
set_clock_uncertainty 0.2500 [get_clocks clk]

# ====================================================================
# 3. Explicit Peripheral I/O Boundaries (Referencing Master clk Only)
# ====================================================================
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports ui_in]
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports uio_in]

set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uo_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_oe]

# 4. Constrain Output Drive Loads (Match Tiny Tapeout Pad Ring Capacitance)
set_load 0.0334 [get_ports uo_out]
set_load 0.0334 [get_ports uio_out]
set_load 0.0334 [get_ports uio_oe]
