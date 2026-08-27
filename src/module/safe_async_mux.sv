/*
 * Copyright 2026 circuitli (https://github.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://apache.org
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
    // SECURE OUTPUT BOUNDARY WITH SYSTEMVERILOG X-PROPAGATION BLOCK
    // Using '===' ensures that if glitch_free_y is X or Z, the condition 
    // evaluates to a strict, clean FALSE (1'b0). This forces 'y' to a 
    // safe, predictable 1'b0, stopping the RTL X leak at the gate.
    // =========================================================================
    assign y = (glitch_free_y === 1'b1) ? 1'b1 : 1'b0;

endmodule

`default_nettype wire
`endif
