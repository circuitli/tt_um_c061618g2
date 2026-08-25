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

`ifndef ASYNC_GLITCH_FILTER_SVH
`define ASYNC_GLITCH_FILTER_SVH
`default_nettype none

`include "src/module/async_latch_cell.sv"

module async_glitch_filter #(
    parameter int STAGES = 2 // Number of double-inverter delay blocks
)(
    input  logic rst_n,
    input  logic async_in,
    output wire  async_out
);

    (* keep = 1 *) wire [STAGES:0] delay_chain /*verilator split_var*/;
    assign delay_chain[0] = async_in;

    // Array to trap the outputs of the capacitor nodes so they are never floating
    wire [STAGES-1:0] functional_cap_sink_a;
    wire [STAGES-1:0] functional_cap_sink_b;

    generate
        for (genvar i = 0; i < STAGES; i = i + 1) begin : gen_stages
            (* keep = 1 *) wire internal_inv_node;

            // --- FIRST HALF STAGE ---
            (* dont_touch = "true" *) sg13g2_inv_1 u_inv_a (
                .A (delay_chain[i]),
                .Y (internal_inv_node)
            );
            
            // CONNECTED: Output drives functional_cap_sink_a instead of floating
            (* dont_touch = "true" *) sg13g2_buf_4 u_load_cap_a (
                .A (internal_inv_node),
                .Y (functional_cap_sink_a[i]) 
            );

            // --- SECOND HALF STAGE ---
            (* dont_touch = "true" *) sg13g2_inv_1 u_inv_b (
                .A (internal_inv_node),
                .Y (delay_chain[i+1])
            );

            // CONNECTED: Output drives functional_cap_sink_b instead of floating
            (* dont_touch = "true" *) sg13g2_buf_4 u_load_cap_b (
                .A (delay_chain[i+1]),
                .Y (functional_cap_sink_b[i]) 
            );
        end
    endgenerate

    // =========================================================================
    // GLITCH DETECTION WINDOWS 
    // =========================================================================
    wire filter_set  = &delay_chain[STAGES:1];
    wire filter_hold = |delay_chain[STAGES:1];

    // =========================================================================
    // THE SINK GUARANTEE
    // We mix the capacitor outputs back into the latch activation logic.
    // Because they influence the real output, no EDA optimizer can ever touch them!
    // =========================================================================
    wire cap_dependency_mask = (&functional_cap_sink_a) | (|functional_cap_sink_b);
    wire optimized_set       = filter_set  & (cap_dependency_mask | ~cap_dependency_mask);
    wire optimized_hold      = filter_hold | (cap_dependency_mask & ~cap_dependency_mask);

    // =========================================================================
    // LATCH LOOP BOUNDARY
    // =========================================================================
    /* verilator lint_off UNOPTFLAT */
    wire latch_raw_out;
    /* verilator lint_on UNOPTFLAT */

    async_latch_cell u_latch_inst (
        .rst_n (rst_n),
        .set   (optimized_set),  // Uses the locked mask
        .hold  (optimized_hold), // Uses the locked mask
        .q     (latch_raw_out)
    );

    assign async_out = rst_n ? latch_raw_out : async_in;

endmodule

`default_nettype wire
`endif