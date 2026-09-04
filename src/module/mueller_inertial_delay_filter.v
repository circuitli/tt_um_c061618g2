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

`ifndef MUELLER_INERTIAL_DELAY_FILTER_SV
`define MUELLER_INERTIAL_DELAY_FILTER_SV
`default_nettype none

`include "src/tech/dlygate4sd3.v"
`include "src/tech/aoi21_1.v"

// =========================================================================
// UNIVERSAL PORTABLE MUELLER INERTIAL DELAY FILTER
// =========================================================================

module mueller_inertial_delay_filter (
    input wire in,
    output wire out
);
    wire delayed_path;
    wire c_element_out;

    // 1. Direct structural instantiation of your universal delay gate macro
    dlygate4sd3 u_dly (
        .A(in),
        .X(delayed_path)
    );

    // 2. Direct structural instantiation of your universal AOI consensus gate
    aoi21_1 u_mueller_latch (
        .A1(in),
        .A2(delayed_path),
        .B1(c_element_out),
        .Y(out)
    );

    // 3. Complete the physical feedback loop to lock the state memory
    assign c_element_out = !out;

endmodule

`default_nettype wire
`endif // SAFE_ASYNC_MUX_FORMAL_SVH
