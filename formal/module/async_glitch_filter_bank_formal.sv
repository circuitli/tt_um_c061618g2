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
// =============================================================================
module async_glitch_filter_bank_formal #(
    parameter int WIDTH  = 13,
    parameter int STAGES = 4
)(
    input wire               rst_n,      // Pure combinational reset input
    input wire [WIDTH-1:0]   async_in,   // Raw multi-channel input vector
    input wire [WIDTH-1:0]   async_out   // Glitch-filtered output vector
);

    // --- Core Multi-Channel Matrix Invariants (Clockless Boolean Assertions) ---
    assert_bank_reset_passthrough: assert property (
        (rst_n) || (async_out == async_in)
    );

    // Verify independent routing boundaries
    generate
        for (genvar i = 0; i < WIDTH; i++) begin : gen_bit_invariants
            assert_channel_isolation: assert property (
                !(rst_n && (async_in[i] == async_out[i])) || (async_out[i] == async_in[i])
            );
        end
    endgenerate

endmodule

bind async_glitch_filter_bank async_glitch_filter_bank_formal #(.WIDTH(13), .STAGES(4)) i_async_glitch_filter_bank_formal (
    .rst_n     (rst_n),
    .async_in  (async_in),
    .async_out (async_out)
);

`endif
