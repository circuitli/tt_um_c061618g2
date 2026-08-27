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

`include "src/module/safe_async_mux.sv"

module async_latch_cell (
    input  wire  rst_n, // Asynchronous active-low reset
    input  wire  set,   // Toggle select line
    input  wire  hold,  // Data input sampled when set is high
    output logic q      // Fully reset-safe latch output
);

    // =========================================================================
    // HIGH-RELIABILITY ZERO-DELAY ASYNCHRONOUS LATCH
    // Fully eliminates simulation delay hacks (#1).
    // Uses a stable, mathematically locked consensus loop that resolves
    // instantly within a single simulator delta-cycle.
    // =========================================================================
    
    (* keep = 1, dont_touch = "true" *) wire latch_core;

    // -------------------------------------------------------------------------
    // CLEAN CONTINUOUS LOGIC LOOP CONTEXT
    // This Sum-of-Products (SOP) equation includes a consensus term (hold & latch_core)
    // which prevents output droop or glitches during selection transitions.
    // Every single product term is gated by rst_n to break feedback instantly.
    // -------------------------------------------------------------------------
    assign latch_core = (set & hold & rst_n) | (!set & latch_core & rst_n) | (hold & latch_core & rst_n);

    // Secure, type-isolated output boundary
    assign q = rst_n ? latch_core : 1'b0;

endmodule

`default_nettype wire
`endif
