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

`ifndef ASYNC_LATCH_CELL_SV
`define ASYNC_LATCH_CELL_SV
 
`default_nettype none

module async_latch_cell (
    input  logic rst_n,
    input  logic set,
    input  logic hold,
    // Forces Icarus to treat the output net structurally
    output wire  q
);

    // =========================================================================
    // STRUCTURAL READ-WRITE WIRE NETWORK
    // Under FORMAL & OpenLane ASIC: Maps directly to immediate hardware gates.
    // Under COCOTB (Icarus): Uses an explicit #1 delay on structural wire loops
    // to step the simulator timeline wheel forward and prevent Time-0 stalls.
    // =========================================================================
    wire latch_gated_fb;
    wire latch_forward;

    `ifdef COCOTB_SIM
        // Structural wire delay forces Icarus to yield and advance the time wheel
        assign #1 latch_gated_fb = q & hold;
    `else
        assign latch_gated_fb = q & hold;
    `endif

    assign latch_forward  = set | latch_gated_fb;
    assign q              = rst_n ? latch_forward : 1'b0;

endmodule

`endif
