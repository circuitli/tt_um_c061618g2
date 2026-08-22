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

`ifndef ANTI_GLITCH_FILTER_SVH
`define ANTI_GLITCH_FILTER_SVH
`default_nettype none

(* keep_hierarchy = 1 *)
module anti_glitch_filter #(
    parameter bit RESET_VALUE = 1'b1  // The literal bit driven ONLY during a raw hardware reset
) (
    input  logic clk,              // System clock input for discrete time sampling
    input  logic rst_n,            // Asynchronous active-low global hardware reset
    input  logic TESTMODE_n,       // Full production test mode override switch
    input  logic raw_signal_in,    // Raw input wire carrying combinational hazards
    output logic clean_signal_out  // Glitch-isolated, stabilized output signal
);

    // Structural interleaved pipeline registers
    (* keep = 1, dont_touch = 1 *) logic filter_stage1;
    (* keep = 1, dont_touch = 1 *) logic filter_stage2;
    (* keep = 1, dont_touch = 1 *) logic filter_stage3; 

        // 1. First two stages capture data early on the falling edge (negedge)
    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_stage1 <= RESET_VALUE;
            filter_stage2 <= RESET_VALUE;
        end else begin
            filter_stage1 <= raw_signal_in;
            filter_stage2 <= filter_stage1;
        end
    end

    // 2. Pure Synchronous Output Register (Standard Asynchronous Reset Mapping)
    // We remove the nested TESTMODE_n branch from here to eliminate redundancy!
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_stage3 <= RESET_VALUE;
        end else begin
            filter_stage3 <= filter_stage2; // Direct, un-shielded register path
        end
    end

    // 3. Optimized Structural Output Routing Matrix
    // Merges test mode and asynchronous reset priority into a single, clean cell track.
    assign clean_signal_out = (!rst_n)      ? RESET_VALUE : 
                             (!TESTMODE_n) ? raw_signal_in : filter_stage3;

endmodule
`endif
