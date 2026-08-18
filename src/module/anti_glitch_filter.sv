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
    input  logic TESTMODE_n,         // Full production test mode override switch
    input  logic raw_signal_in,    // Raw input wire carrying combinational hazards
    output logic clean_signal_out  // Glitch-isolated, stabilized output signal
);

    
    logic [1:0] shift_reg;
    logic       filtered_signal;

    // ----------------------------------------------------------------
    // 1. Sequential Sampling and Hysteresis Voting Core
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg       <= 2'b11; // Active-low idle high default
            filtered_signal <= 1'b1;  // De-asserted default state
        end else begin
            // Shift operations move left: old bit 0 moves to bit 1, new sample enters bit 0
            shift_reg <= {shift_reg[0], raw_signal_in};
            
            // Pure sequential voting logic (No combinational feedback loops)
            if (shift_reg == 2'b00) begin
                filtered_signal <= 1'b0; // Confirmed active-low pulse
            end else if (shift_reg == 2'b11) begin
                filtered_signal <= 1'b1; // Confirmed inactive-high pulse
            end
            // Implicitly retains its previous register value if shift_reg is 2'b01 or 2'b10
        end
    end

    // ----------------------------------------------------------------
    // 2. Full Production DFT Bypass Architecture
    // ----------------------------------------------------------------
    // When TESTMODE is driven high by factory testers, the sequential latency 
    // is completely bypassed. This gives Automated Test Equipment (ATE) direct, 
    // combinational control over input stimulus without stepping through clock cycles.
    assign clean_signal_out = !TESTMODE_n ? raw_signal_in : filtered_signal;

endmodule
`endif