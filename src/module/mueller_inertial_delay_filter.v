/*
 * Copyright 2026 circuitli (https://github.com)
 *
 * Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://cern-ohl.web.cern.ch/
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`ifndef MUELLER_INERTIAL_DELAY_FILTER_V
`define MUELLER_INERTIAL_DELAY_FILTER_V

`include "src/techmap/dlygate4sd3.v"
`include "src/techmap/aoi211_1.v"
`include "src/techmap/inv_1.v"

`default_nettype none

// =========================================================================
// UNIVERSAL PORTABLE MUELLER INERTIAL DELAY FILTER
// =========================================================================

module mueller_inertial_delay_filter (
    input  wire rst_n,      // Active-low global asynchronous reset
    input  wire async_in,   // Asynchronous input signal
    output wire async_out   // Clean, filtered output signal
);

    wire delayed_path;
    wire c_element_state;

    // 1. Structural delay line (filters pulses shorter than this window)
    dlygate4sd3 u_dly (
        .A(async_in),
        .X(delayed_path)
    );

    
    // AOI211 Cell Function: Y = !((A1 & A2) | B1 | C1)
    // We group the input AND condition on one side, and the feedback state
    // qualification loop on the other side using an explicit OR combination.
    
    // To make it hold state when inputs mismatch, the feedback loop requires 
    // an internal boolean masking logic. The absolute cleanest way using your 
    // exact structural cell layers is:
    
    aoi211_1 u_mueller_latch (
        .A1(async_in || delayed_path), // Hold gate: True if either input is high
        .A2(async_out),                // Positive feedback loop
        .B1(async_in && delayed_path), // Set gate: Drives output high when BOTH match 1
        .C1(1'b0),                     // Leave clear pin empty (handled at the output stage)
        .Y(aoi_out)
    );

    // 3. Output Stage: Apply your active-low reset and invert the phase
    // This removes the lockup and keeps the output completely non-inverting.
    wire logic_out;
    inv_1 u_phase_fix (
        .A(aoi_out),
        .Y(logic_out)
    );

    assign async_out = logic_out && rst_n;


endmodule

`default_nettype wire
`endif // SAFE_ASYNC_MUX_FORMAL_SVH
