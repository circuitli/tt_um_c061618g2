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
    input  logic raw_signal_in,    // Raw input wire carrying combinational hazards
    output logic clean_signal_out  // Glitch-isolated, stabilized output signal
);

    logic [1:0] shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg        <= 2'b11; // Active-low idle high default
            clean_signal_out <= 1'b1;  // Synchronous initialization
        end else begin
            shift_reg <= {shift_reg[0], raw_signal_in};
            
            // Pure sequential voting logic (No combinational loops)
            if (shift_reg == 2'b00) begin
                clean_signal_out <= 1'b0;
            end else if (shift_reg == 2'b11) begin
                clean_signal_out <= 1'b1;
            end
            // Implicitly retains its previous register value if shift_reg is 2'b01 or 2'b10
        end
    end

endmodule
`endif