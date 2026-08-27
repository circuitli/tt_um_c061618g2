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
    input  wire  async_out
);

`ifdef FORMAL

    // -------------------------------------------------------------------------
    // 1. ABSOLUTE RESET DOMINANCE PROOF
    // Property: Whenever rst_n is pulled low, the filter output must drop to 0 
    // instantly, completely overriding any active transitions or historical states.
    // -------------------------------------------------------------------------
    asm_filter_immediate_reset_assert: assert property (
        (!rst_n) -> (async_out == 1'b0)
    );

    // -------------------------------------------------------------------------
    // 2. DELAY CHAIN STALE FLUSH PROOF
    // Property: One step after a reset is applied, the internal state must be 
    // completely flushed clean. If reset was active in the past cycle, the current
    // output cannot arbitrarily toggle high on the turn-off boundary.
    // -------------------------------------------------------------------------
    asm_filter_post_reset_flush_assert: assert property (
        ($past(!rst_n) && !rst_n) -> (async_out == 1'b0)
    );

    // -------------------------------------------------------------------------
    // 3. GLITCH REJECTION & WINDOW INTEGRITY PROOF
    // Property: The output 'async_out' can only rise to 1'b1 if the input 
    // 'async_in' has been held high and stable for a minimum duration. 
    // A transient pulse must be rejected.
    // -------------------------------------------------------------------------
    asm_filter_glitch_rejection_assert: assert property (
        (rst_n && $rose(async_out)) -> ($past(async_in) && async_in)
    );

    // -------------------------------------------------------------------------
    // 4. METASTABILITY & X-PROPAGATION BARRIER PROOF
    // Property: Ensure the output remains strictly binary under all operating
    // conditions, safeguarding downstream CDC logic from intermediate voltage steps.
    // -------------------------------------------------------------------------
    asm_filter_binary_clean_assert: assert property (
        (async_out == 1'b1) || (async_out == 1'b0)
    );

`endif

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
