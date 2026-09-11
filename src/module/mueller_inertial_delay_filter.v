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

    // 2. Resettable Mueller C-Element core logic matrix
    // By driving the OR-plane input (B1) with the inverted state register,
    // we balance the output inversion of the AOI cell to establish positive storage.
    aoi211_1 u_mueller_latch (
        .A1(async_in),
        .A2(delayed_path),
        .B1(c_element_state), // Inverted feedback state maintains the loop latch
        .C1(!rst_n),          // High reset level forces AOI output low (Y=0)
        .Y(async_out)
    );

    // 3. Drive the internal feedback inversion to establish stable state retention
    assign c_element_state = !async_out;

endmodule

`default_nettype wire
`endif // SAFE_ASYNC_MUX_FORMAL_SVH
