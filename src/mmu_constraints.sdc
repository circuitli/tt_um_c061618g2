# Copyright 2026 circuitli (https://github.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://apache.org
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ====================================================================
# Synopsys Design Constraints (SDC) - Failsafe Fanout Isolation Profile
# Target: 85.91 MHz Operation (24x Master Crystal Multiplier)
# ====================================================================

# 1. Define Primary Master Clock Input Port (85.91 MHz)
create_clock -name clk -period 11.6400 [get_ports clk]

# 2. Add a Strict 250-Picosecond Guard Band to Protect Against Clock Jitter
set_clock_uncertainty 0.2500 [get_clocks clk]

# 3. DYNAMIC FANOUT ISOLATION LAYER (Prevents TritonCTS Crashes)
# We isolate cross-domain paths by finding the cells driven by the locked sys_clk net.
# This avoids defining an internal clock root that breaks the CTS engine.
if { [info commands get_fanout] != "" } {
    catch {
        set sys_clk_sinks [get_fanout [get_nets sys_clk] -clock_sinks]
        if { \$sys_clk_sinks != "" } {
            set sys_clk_cells [get_cells -of_objects \$sys_clk_sinks]
            set_false_path -from \$sys_clk_cells
            set_false_path -to \$sys_clk_cells
        }
    }
}

# ====================================================================
# 4. Explicit Peripheral I/O Timing Boundaries (Referencing clk Only)
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
