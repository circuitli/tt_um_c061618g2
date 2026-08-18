# ====================================================================
# Synopsys Design Constraints (SDC) - 86 MHz Custom Sync
# ====================================================================

# 1. Define Primary Master Clock Input Window (85.91 MHz)
create_clock -name clk -period 11.6400 [get_ports clk]

# 2. Map the generated clock onto the shift vector
# Traces the combinational delay through the gating assign logic natively
create_generated_clock -name sys_clk \
    -source [get_ports clk] \
    -combinational \
    [get_pins -of_objects [get_cells -hierarchical *sync_stages*] -filter {direction == output}]

# 3. Add a Strict 250-Picosecond Guard Band to Protect Against Jitter
set_clock_uncertainty 0.2500 [get_clocks clk]
set_clock_uncertainty 0.2500 [get_clocks sys_clk]

# 4. Handle Logically Exclusive Paths Across the Test Multiplexer Matrix
set_clock_groups -logically_exclusive \
    -group [get_clocks clk] \
    -group [get_clocks sys_clk]

# 5. Safe Asynchronous Clock Grouping
set_clock_groups -asynchronous \
    -group [get_clocks clk] \
    -group [get_clocks sys_clk]

# ====================================================================
# 6. Explicit Peripheral I/O Boundaries (Referencing clk Only)
# ====================================================================
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports ui_in]
set_input_delay 2.0000 -clock [get_clocks clk] [get_ports uio_in]

set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uo_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_out]
set_output_delay 2.0000 -clock [get_clocks clk] [get_ports uio_oe]

# 7. Constrain Output Drive Loads (Match Tiny Tapeout Pad Ring Capacitance)
set_load 0.0334 [get_ports uo_out]
set_load 0.0334 [get_ports uio_out]
set_load 0.0334 [get_ports uio_oe]
