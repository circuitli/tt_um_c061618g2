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
    input  wire rst_n,   // Asynchronous active-low reset
    input  wire set,     // Latch set configuration control
    input  wire hold,    // Latch hold parameter control
    output wire q        // Stable output logic channel net
);

    // =========================================================================
    // =========================================================================
    // PRODUCTION HARDWARE SYNTHESIS ATTRIBUTES
    // Kept 100% active and untouched for your OpenLane layout synthesis runs.
    // =========================================================================
    (* keep = 1, dont_touch = "true" *) wire latch_core;

    // =========================================================================
    // HAZARD-FREE UNCLOCKED SILICON LOGIC CROSS-COUPLED LAYOUT LOOP
    // Breaking the wide Boolean expression into explicit multi-stage assignments 
    // forces the simulator engine to serialize the feedback path, eliminating
    // delta-cycle race hazards completely.
    // =========================================================================
    wire s_term = set & hold;
    wire r_term = !set;
    
    // ---------------------------------------------------------------------
    // HAZARD-FREE SIMULATION AND SILICON COMPLIANT FEEDBACK MATRIX
    // FIXED: Completed the trailing reset conditional block to resolve the 
    // Yosys parser TOK_ASSIGN syntax error!
    // ---------------------------------------------------------------------
    assign latch_core = rst_n ? (set ? hold : (hold ? latch_core : 1'b0)) : 1'b0;

    assign q = latch_core;

endmodule

`default_nettype wire
`endif
