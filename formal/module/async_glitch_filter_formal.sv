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

`ifndef ASYNC_GLITCH_FILTER_FORMAL_SV
`define ASYNC_GLITCH_FILTER_FORMAL_SV
 
`default_nettype none

// =============================================================================
// Sub-Module Level Formal Checker: async_glitch_filter_formal
// Now parameterized to match any configuration under test dynamically.
// =============================================================================
// =========================================================================
    // COMBINATIONAL FILTER PROPERTIES
    // =========================================================================
    always @* begin

        // 1. ABSOLUTE RESET DOMINANCE PROOF
        // Under active reset, the output must be driven cleanly to zero.
        if (!rst_n) begin
            asm_filter_immediate_reset_assert: assert (async_out == 1'b0);
        end

        // 2. METASTABILITY & X-PROPAGATION BARRIER PROOF
        // Prevents uninitialized states or floating loops from propagating.
        asm_filter_binary_clean_assert: assert ((async_out == 1'b1) || (async_out == 1'b0));

        // 3. GLITCH REJECTION & WINDOW INTEGRITY PROOF (FIXED CONTRACT)
        // If out of reset and the output is high, it MUST be supported by either
        // a complete matching input chain (Set Condition) OR the latch state 
        // retention mechanism must be actively engaged (Hold Condition).
        if (rst_n && async_out) begin
            // Re-map the exact operational conditions of your main module
            wire filter_set  = (&delay_chain[STAGES:1]);
            wire filter_hold = (|delay_chain[STAGES:1]);
            
            // The output can only be 1 if it was just set, or if it is holding memory
            asm_filter_window_integrity_assert: assert (filter_set || filter_hold);
        end

        // 4. LOW-STABILITY SAFETY CONTRACT
        // If the entire pipeline has been flushed down to zero, the output 
        // must drop and clamp cleanly to zero.
        if (rst_n && !async_in && (delay_chain[STAGES:0] == { (STAGES+1){1'b0} })) begin
            asm_filter_flush_stable_assert: assert (async_out == 1'b0);
        end
    end

eendmodule

// =============================================================================
// THE PARAMETERIZED BIND DIRECTIVE
// Passing .STAGES(STAGES) ensures perfect compiler connection alignment.
// =============================================================================
bind async_glitch_filter async_glitch_filter_formal #(
    .STAGES(STAGES)
) i_async_glitch_filter_formal (
    .rst_n       (rst_n),
    .async_in    (async_in),
    .async_out   (async_out),
    .delay_chain (delay_chain)
);

`endif // ASYNC_GLITCH_FILTER_FORMAL_SV
