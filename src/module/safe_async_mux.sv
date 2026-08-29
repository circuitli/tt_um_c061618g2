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

`ifndef SAFE_ASYNC_MUX_SVH
`define SAFE_ASYNC_MUX_SVH
`default_nettype none

module safe_async_mux (
    input  wire  rst_n, // Asynchronous active-low reset
    input  wire  a0,    // Selected data channel when s == 0
    input  wire  a1,    // Selected data channel when s == 1
    input  wire  s,     // Active select control line
    output logic y      // Glitch-free, type-isolated output net
);

    // 1. Declare an internal wire with preservation pragmas to lock the gates
    (* keep = 1, dont_touch = "true" *) wire glitch_free_y;

    // 2. Continuous hazard-free combinational logic assignment with consensus loop.
    // Every single term is gated by 'rst_n' to ensure that if rst_n == 0, 
    // the intermediate node drops to 0 instantly without any intermediate glitch states.
    assign glitch_free_y = (a0 & ~s & rst_n) | (a1 & s & rst_n) | (a0 & a1 & rst_n);

    // =========================================================================
    // HAZARD-FREE AND SIMULATOR-BALANCED SECURE OUTPUT BOUNDARY
    // Replaces '===' with a strict 2-state identity condition. This maps
    // seamlessly to both formal solvers and dynamic 4-state event simulators,
    // ensuring the output net settles with the correct expected binary state.
    // =========================================================================
    wire static_y_valid = (glitch_free_y == 1'b1);
    
    assign y = rst_n ? (static_y_valid ? 1'b1 : 1'b0) : 1'b0;

endmodule

`default_nettype wire
`endif
