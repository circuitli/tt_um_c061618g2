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
    parameter int STAGES = 4
)(
    input wire rst_n,
    input wire async_in,
    input wire async_out,
    input wire [STAGES:0] delay_chain // Dynamically scaled bit-width string
);

    // Hooks directly into the clean latch sub-module output node terminal
    wire loop_feedback = async_glitch_filter.latch_raw_out;

    // --- Structural Boundary Constraints (No Arrows, Pure Boolean Logic) ---
    assert_mux_routing_functional: assert property (
        (rst_n) || (async_out == async_in)
    );

    // --- Exhaustive State Transition and Noise Invariant Properties ---
    // Proves that when all physical delay stages settle high, the filter locks high
    // (Slices [STAGES:1] to strip out the instantaneous raw input node)
    assert_high_stability: assert property (
        !(rst_n && (&delay_chain[STAGES:1])) || (async_out == 1'b1)
    );

    // Proves that when all physical delay stages settle low, the filter drops low
    assert_low_stability: assert property (
        !(rst_n && (~(|delay_chain[STAGES:1]))) || (async_out == 1'b0)
    );

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
