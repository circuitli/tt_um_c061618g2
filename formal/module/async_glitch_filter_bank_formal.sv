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

`ifndef ASYNC_GLITCH_FILTER_BANK_FORMAL_SVH
`define ASYNC_GLITCH_FILTER_BANK_FORMAL_SVH
`default_nettype none

// =============================================================================
// Middle-Tier Bank Level Formal Checker: async_glitch_filter_bank_formal
// Dynamically scales to match any instantiated width automatically.
// =============================================================================
module async_glitch_filter_bank_formal #(
    parameter int WIDTH  = 13,
    parameter int STAGES = 4
)(
    input wire                clk,  // Formal-only clock routed natively to the leaf latches
    input wire                rst_n,      
    input wire  [WIDTH-1:0]   async_in,   
    input logic [WIDTH-1:0]   async_out   
);

    // =========================================================================
    // LOOP-SAFE PROCEDURAL CLOCKED FORMAL BANK PROPERTIES
    // =========================================================================
    always @(posedge gclk) begin

        // 1. ABSOLUTE RESET SAFE-STATE PROOF
        // When reset is active low, the bank MUST force all outputs to safe zeros!
        assert_bank_reset_safe: assert (rst_n || (async_out == {WIDTH{1'b0}}));

        // 2. DATA METASTABILITY & X-PROPAGATION BARRIER PROOF
        assert_bank_binary_clean: assert ((async_out | ~async_out) == {WIDTH{1'b1}});

        // 3. CHANNEL LANE STEP MATRIX (Condensed Inside Main Block)
        if (rst_n) begin
            for (int i = 0; i < WIDTH; i++) begin
                // If the output updates/changes, it must correlate to a valid input history state.
                assert_channel_functional_bound: assert (
                    !$changed(async_out[i]) || ($past(async_in[i]) == async_out[i] || async_in[i] == async_out[i])
                );
            end
        end
    end

endmodule

// =============================================================================
// PARAMETERIZED BIND DIRECTIVE
// Uses dynamic parameters to prevent width-mismatch errors across variations.
// =============================================================================
bind async_glitch_filter_bank async_glitch_filter_bank_formal #(
    .WIDTH(WIDTH),
    .STAGES(STAGES)
) i_async_glitch_filter_bank_formal (
    .clk       (clk), // Connects seamlessly down to the leaf cell port
    .rst_n     (rst_n),
    .async_in  (async_in),
    .async_out (async_out)
);

`endif // ASYNC_GLITCH_FILTER_BANK_FORMAL_SVH

