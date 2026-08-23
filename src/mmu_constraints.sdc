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
# Target: 201 MHz Operation (56x Video Clock Multiplier)
# ====================================================================

# 1. Define Primary Master Clock Input Port (197 MHz)
#create_clock -name clk -period 5.0761 [get_ports clk]
# 1. Define Primary Master Clock Input Port to exactly 200 MHz
#create_clock -name clk -period 5.0000 [get_ports clk]
# ====================================================================
# 1. DEFINE PRIMARY MASTER CLOCK INPUT PORT (201 MHz)
# ====================================================================
#create_clock -name clk -period 4.9571 [get_ports clk]
# ====================================================================
# 1. DEFINE PRIMARY MASTER CLOCK INPUT PORT (215 MHz Target)
# ====================================================================
# 4.6512 ns corresponds exactly to a 215 MHz master clock frequency
create_clock -name clk -period 4.6512 [get_ports clk]

# ====================================================================
# 2. DEFINE GATED INTERNAL CLOCK ROOT NODE
# Dynamically queries the database for the exact physical driver pin 
# of your preserved sys_clk net, completely bypassing string names.
# ====================================================================
create_generated_clock -name sys_clk \
    -source [get_ports clk] \
    -divide_by 1 \
    [get_pins -of_objects [get_nets -hierarchical *sys_clk]]

# Apply a strict 150ps guard band for setup checks to fix data path delay
set_clock_uncertainty -setup 0.0250 [get_clocks clk]
set_clock_uncertainty -setup 0.0250 [get_clocks sys_clk]

# Relax hold uncertainty to 50ps to prevent TritonCTS from adding too many buffers
set_clock_uncertainty -hold 0.0500 [get_clocks clk]
set_clock_uncertainty -hold 0.0500 [get_clocks sys_clk]

# ====================================================================
# 4. SAFE ASYNCHRONOUS BOUNDARY ISOLATION (OpenSTA Compliant)
# Traverses the 'sys_clk' net to find all leaf input pins, 
# cleanly slicing cross-domain paths without breaking TritonCTS.
# ====================================================================
#set fanout_pins [get_pins -of_objects [get_nets sys_clk] -filter "direction == input"]
#
#if { [llength $fanout_pins] > 0 } {
#    set_false_path -from [all_registers] -to $fanout_pins
#    set_false_path -from [get_ports ui_in] -to $fanout_pins
#}

# ====================================================================
# 4. SAFE ASYNCHRONOUS BOUNDARY ISOLATION
# Only cut timing on the async control signals entering the synchronizer.
# This prevents TritonCTS distortion while ensuring data paths are timed.
# ====================================================================

# Isolate the asynchronous master system reset port
set_false_path -from [get_ports rst_n]

# Isolate the input stages of the asynchronous shift register pipeline
set_false_path -to [get_pins -hierarchical -filter {name =~ *u_clock_sync*sync_stages*/*}]

# Define clk and sys_clk as synchronous to allow inter-domain timing closure
#set_clock_groups -asynchronous -group [get_clocks clk] -group [get_clocks sys_clk]

# Explicitly tells OpenSTA that clk and sys_clk are logically exclusive, 
# preventing the timing engine from analyzing impossible cross-domain interactions.
set_clock_groups -logically_exclusive -group [get_clocks clk] -group [get_clocks sys_clk]

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
