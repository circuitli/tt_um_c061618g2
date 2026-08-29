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

`ifndef ASYNC_LATCH_CELL_FORMAL_SV
`define ASYNC_LATCH_CELL_FORMAL_SV
 
`default_nettype none

module async_latch_cell_formal (
    input  wire  rst_n,
    input  wire  set,
    input  wire  hold,
    input  wire  q
);

    // =========================================================================
    // COMBINATIONAL FORMAL PROPERTIES
    // The always @* block evaluates continuously whenever any signal changes,
    // providing clockless coverage while satisfying the Yosys parser.
    // =========================================================================
    always @* begin
        
        // 1. ASYNCHRONOUS RESET VERIFICATION
        asm_latch_reset_assert: assert (rst_n || (q == 1'b0));

        // 2. FUNCTIONAL LATCH TRANSITION VERIFICATION
        // If out of reset and set is asserted, output matches hold state
        asm_latch_set_assert: assert (!(rst_n && set) || (q == hold));

        // 3. X/Z METASTABILITY ISOLATION PROOF
        asm_latch_binary_clean_assert: assert ((q == 1'b1) || (q == 1'b0));

    end

endmodule

// 2. RE-ROUTE LATCH BIND DOWNWARD NATIVELY
// Placing this at the top wrapper level allows it to use the local 'clk' wire directly
bind async_latch_cell async_latch_cell_formal i_async_latch_cell_formal (
    .rst_n (rst_n),
    .set   (set),
    .hold  (hold),
    .q     (q)
);

`endif
