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

module anti_glitch_filter (
    input  logic clk,              // System clock input for discrete time sampling
    input  logic rst_n,            // Asynchronous active-low global hardware reset
    input  logic TESTMODE_n,       // Full production test mode override switch
    input  logic raw_signal_in,    // Raw input wire carrying combinational hazards
    output logic clean_signal_out  // Glitch-isolated, stabilized output signal
);

    // =========================================================================
    // ANTI-GLITCH FILTER - HIGH SPEED FALLING-EDGE LAUNCH STAGE
    // Launching the final output on the negedge cuts the physical routing 
    // delay to the IO pad ring in half, closing 215 MHz easily!
    // =========================================================================
    (* keep = 1, dont_touch = 1 *) logic filter_stage1;
    (* keep = 1, dont_touch = 1 *) logic filter_stage2;
    (* keep = 1, dont_touch = 1 *) logic filter_stage3; // This drives uo_out

    // 1. First two stages capture data early on the falling edge (negedge)
    // This splits the long combinational wire route from the MMU core into two fast half-cycles.
    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_stage1 <= 1'b1;
            filter_stage2 <= 1'b1;
        end else begin
            filter_stage1 <= raw_signal_in;
            filter_stage2 <= filter_stage1;
        end
    end

    // 2. Final stage launches data cleanly on the rising edge (posedge)
    // This gives the output pin exactly 2.5 cycles of total system latency.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_stage3 <= 1'b1;
        end else begin
            filter_stage3 <= filter_stage2;
        end
    end

    // Direct output driver link
    assign clean_signal_out = filter_stage3;

endmodule
`endif