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

`ifndef ASYNC_LATCH_UDP_SV
`define ASYNC_LATCH_UDP_SV
 
`default_nettype none

// Pure clockless Level-Sensitive Asynchronous Latch Primitive
primitive async_latch_udp (
    q, rst_n, set, hold
);
    // Explicitly define port directions and types on separate lines
    output reg q,
    input rst_n,
    input set,
    input hold

    // Table initialization parameter for the simulator queue
    initial q = 1'b1; 

    // Structural Truth Table Layout
    // rst_n  set   hold   current_q : next_q
    table
        0      ?     ?   :   ?     :   0 ; // Active-low clear override
        1      1     ?   :   ?     :   1 ; // Set takes absolute priority
        1      0     1   :   ?     :   1 ; // Maintain high while hold is active
        1      0     0   :   ?     :   0 ; // Drop to low when hold window shuts
    endtable
endprimitive

`default_nettype wire
`endif