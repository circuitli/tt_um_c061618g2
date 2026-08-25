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
    parameter int STAGES = 4
)(
    input  logic rst_n,
    input  logic async_in,
    output wire  async_out
);

    // Packed variable split to prevent flat evaluation dependencies
    wire [STAGES-1:0] delay_chain /*verilator split_var*/;

    // =========================================================================
    // CASCADED ASYNCHRONOUS BUFFER TREE (ONE-WAY BALANCED TIMELINE)
    // Direct wire synthesis assignments. The #1 simulation hacks are removed
    // since our synchronized SDC templates handle physical gate-balancing.
    // =========================================================================
    generate
        if (STAGES > 1) begin : gen_delay_chain
            assign delay_chain[0] = async_in;
            for (genvar i = 1; i < STAGES; i = i + 1) begin : gen_stages
                assign delay_chain[i] = delay_chain[i-1];
            end
        end else begin : gen_single_stage
            assign delay_chain[0] = async_in;
        end
    endgenerate

    wire filter_set  = &delay_chain;
    wire filter_hold = |delay_chain;

    // =========================================================================
    // LATCH LOOP EXEMPTION BLOCK
    // =========================================================================
    /* verilator lint_off UNOPTFLAT */
    wire latch_raw_out;
    /* verilator lint_on UNOPTFLAT */

    async_latch_cell u_latch_inst (
        .rst_n (rst_n),
        .set   (filter_set),
        .hold  (filter_hold),
        .q     (latch_raw_out)
    );

    // Clean, direct passthrough routing multiplexer stage
    assign async_out = rst_n ? latch_raw_out : async_in;

endmodule

`endif