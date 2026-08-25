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
    input  logic a0, // Selected when s == 0
    input  logic a1, // Selected when s == 1
    input  logic s,  // Select line
    output wire  y   // Glitch-free output
);

    // Single-line glitch-free asynchronous MUX equation with cover term
    (* dont_touch = "true" *) assign y = (a0 & ~s) | (a1 & s) | (a0 & a1);

endmodule

`default_nettype wire
`endif
