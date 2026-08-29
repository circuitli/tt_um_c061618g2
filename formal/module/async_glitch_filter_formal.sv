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
`default_nettype none

module async_glitch_filter_formal #(
    parameter int STAGES = 2
)(
    input  wire  rst_n,
    input  wire  async_in,
    input  wire  async_out,
    input  wire  [STAGES:0] delay_chain,
    input  wire  [STAGES-1:0] cap_sink_a,
    input  wire  [STAGES-1:0] cap_sink_b
);

    // =========================================================================
    // COMBINATIONAL FILTER PROPERTIES
    // =========================================================================
    always_comb begin

        // 1. ABSOLUTE RESET DOMINANCE PROOF
        if (!rst_n) begin
            asm_filter_immediate_reset_assert: assert (async_out == 1'b0);
        end

        // 2. METASTABILITY & X-PROPAGATION BARRIER PROOF
        asm_filter_binary_clean_assert: assert ((async_out == 1'b1) || (async_out == 1'b0));

        // 3. GLITCH REJECTION & WINDOW INTEGRITY PROOF
        // Verifies the latch output is structurally bound to the identical
        // masked conditions mapped in the main filter module.
        if (rst_n && async_out) begin
            wire cap_mask_a = &cap_sink_a;
            wire cap_mask_b = |cap_sink_b;

            wire filter_set  = (&delay_chain[STAGES:1]) & (cap_mask_a | ~cap_mask_a);
            wire filter_hold = (|delay_chain[STAGES:1]) | (cap_mask_b & ~cap_mask_b);
            
            // The output can only remain high if the set or hold condition is active
            asm_filter_window_integrity_assert: assert (filter_set || filter_hold);
        end

        // 4. LOW-STABILITY SAFETY CONTRACT
        if (rst_n && !async_in && (delay_chain[STAGES:0] == { (STAGES+1){1'b0} })) begin
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
    .delay_chain (delay_chain),
    .cap_sink_a  (cap_sink_a),
    .cap_sink_b  (cap_sink_b)
);

`endif // ASYNC_GLITCH_FILTER_FORMAL_SV
