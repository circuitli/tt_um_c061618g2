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

`ifndef ASYNC_LATCH_CELL_FORMAL_SV
`define ASYNC_LATCH_CELL_FORMAL_SV
 
`default_nettype none

module async_latch_cell_formal (
    input  wire  clk,   // Virtual verification clock port to drive the temporal properties!
    input  wire  rst_n,
    input  wire  set,
    input  wire  hold,
    input  wire  q
);

`ifdef FORMAL

    // =========================================================================
    // FIXED LOOP-SAFE PROCEDURAL CLOCKED FORMAL PROPERTIES
    // Moving assertions inside always @(posedge clk) fixes the unexpected '@'
    // syntax error completely while keeping your timeline unrolled!
    // =========================================================================
    always @(posedge clk) begin
        
        // 1. ASYNCHRONOUS RESET VERIFICATION
        asm_latch_reset_assert: assert (rst_n || (q == 1'b0));

        // 2. FUNCTIONAL LATCH TRANSITION VERIFICATION
        // If out of reset and set is asserted, output matches hold state
        asm_latch_set_assert: assert (!(rst_n && set) || (q == hold));

        // If out of reset and set falls, output must remain stable (latch hold)
        asm_latch_hold_assert: assert (!(rst_n && !set) || $stable(q));

        // 3. X/Z METASTABILITY ISOLATION PROOF
        asm_latch_binary_clean_assert: assert ((q == 1'b1) || (q == 1'b0));

    end

`endif

endmodule

// =========================================================================
// PROPERTY INTERFACE BIND HOOKS (VIRTUAL WORKAROUND RE-INJECTION)
// Traverses the hierarchy to pass the outermost Tiny Tapeout wrapper clock
// directly into the formal layer port boundary!
// =========================================================================
bind async_latch_cell async_latch_cell_formal i_async_latch_cell_formal (
    .clk   (tt_um_c061618g2.clk), // Maps parent clock down to satisfy the formal port
    .rst_n (rst_n),
    .set   (set),
    .hold  (hold),
    .q     (q)
);

`endif
