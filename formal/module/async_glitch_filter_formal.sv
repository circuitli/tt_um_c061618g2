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

`ifndef ASYNC_GLITCH_FILTER_FORMAL_SV
`define ASYNC_GLITCH_FILTER_FORMAL_SV
 
`default_nettype none

// =============================================================================
// Sub-Module Level Formal Checker: async_glitch_filter_formal
// Now parameterized to match any configuration under test dynamically.
// =============================================================================
module async_glitch_filter_formal #(
    parameter int STAGES = 2
)(
    input  wire  rst_n,
    input  wire  async_in,
    input  wire  async_out,
    input  wire  [STAGES:0]     delay_chain  // FIXED: Added missing tracking input port wire vector!
);

    // =========================================================================
    // COMBINATIONAL FILTER PROPERTIES
    // Uses structural tracking across the delay chain vector to eliminate
    // the need for $past, $rose, or formal sampling clocks entirely!
    // =========================================================================
    always @* begin

        // 1. ABSOLUTE RESET DOMINANCE PROOF
        asm_filter_immediate_reset_assert: assert (rst_n || (async_out == 1'b0));

        // 2. METASTABILITY & X-PROPAGATION BARRIER PROOF
        asm_filter_binary_clean_assert: assert ((async_out == 1'b1) || (async_out == 1'b0));

        // 3. GLITCH REJECTION & WINDOW INTEGRITY PROOF
        // If out of reset and the output rises or is high, the internal delay chain 
        // stages must validate that the input was stable across the window.
        if (rst_n && async_out) begin
            // If the output is high, the entire filtering stage window must be full
            asm_filter_window_integrity_assert: assert (delay_chain[STAGES:0] == { (STAGES+1){1'b1} });
        end

        // 4. LOW-STABILITY SAFETY CONTRACT
        if (rst_n && !async_in && (delay_chain[STAGES:0] == { (STAGES+1){1'b0} })) begin
            // If the input has been low long enough to completely clear the pipeline, 
            // the output must stay clamped to zero.
            asm_filter_flush_stable_assert: assert (async_out == 1'b0);
        end
    end

endmodule

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
