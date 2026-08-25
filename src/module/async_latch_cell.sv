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
    output wire  q
);

    // =========================================================================
    // STRUCTURAL RECURSIVE FEEDBACK LOOP
    // Keep attributes protect the combinatorial latch from being flattened 
    // or optimized away during the OpenLane gs130g2 synthesis pass.
    // =========================================================================
    (* keep = 1 *) wire latch_gated_fb;
    (* keep = 1 *) wire latch_forward;

    `ifdef COCOTB_SIM
        // MANDATORY: Forces Icarus Verilog to advance its delta time wheel
        // and prevents simulator lockups during clockless evaluation loops.
        assign #1 latch_gated_fb = q & hold;
    `else
        // NATIVE SILICON: Maps to a clean standard cell gate network.
        assign latch_gated_fb = q & hold;
    `endif

    assign latch_forward  = set | latch_gated_fb;
    assign q              = rst_n ? latch_forward : 1'b0;

endmodule

`endif
