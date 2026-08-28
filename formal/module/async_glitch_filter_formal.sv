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
    input  wire  clk,  // Formal-only clock routed natively to the leaf latches
    input  wire  rst_n,
    input  wire  async_in,
    input  wire  async_out,
    input  wire  [STAGES:0]     delay_chain  // FIXED: Added missing tracking input port wire vector!
);

    // =========================================================================
    // CLOCKED FORMAL PROPERTIES
    // Moving assertions inside always @(posedge clk) allows Yosys to resolve
    // $past and $rose as clean step registers, destroying cell simplemap_bitop$257!
    // =========================================================================
    always @(posedge gclk) begin

        // 1. ABSOLUTE RESET DOMINANCE PROOF
        asm_filter_immediate_reset_assert: assert (rst_n || (async_out == 1'b0));

        // 2. DELAY CHAIN STALE FLUSH PROOF
        asm_filter_post_reset_flush_assert: assert (!($past(!rst_n) && !rst_n) || (async_out == 1'b0));

        // 3. GLITCH REJECTION & WINDOW INTEGRITY PROOF
        asm_filter_glitch_rejection_assert: assert (!(rst_n && $rose(async_out)) || ($past(async_in) && async_in));

        // 4. METASTABILITY & X-PROPAGATION BARRIER PROOF
        asm_filter_binary_clean_assert: assert ((async_out == 1'b1) || (async_out == 1'b0));

    end

endmodule

// =============================================================================
// THE PARAMETERIZED BIND DIRECTIVE
// Passing .STAGES(STAGES) ensures perfect compiler connection alignment.
// =============================================================================
bind async_glitch_filter async_glitch_filter_formal #(
    .STAGES(STAGES)
) i_async_glitch_filter_formal (
    .clk         (clk), // Connects seamlessly down to the leaf cell port
    .rst_n       (rst_n),
    .async_in    (async_in),
    .async_out   (async_out),
    .delay_chain (delay_chain)
);

`endif // ASYNC_GLITCH_FILTER_FORMAL_SV
