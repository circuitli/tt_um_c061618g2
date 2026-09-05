/*
 * Copyright 2026 circuitli (https://github.com)
 *
 * Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://cern-ohl.web.cern.ch/
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`ifndef SIGNAL_DIVIDER_BY_4_FORMAL_SV
`define SIGNAL_DIVIDER_BY_4_FORMAL_SV
`default_nettype none

module signal_divider_by_4_formal (
    input  wire clk,
    input  wire rst_n,
    input  wire signal_in,
    input  wire signal_out,
    input  wire [1:0] sample_cnt
);

    // Track initialization step to skip cycle 0 checks
    wire f_past_valid = 1'b0;
    always_ff @(posedge clk) begin
        f_past_valid <= 1'b1;
    end

    // Use a single, clocked procedural block to enforce the mathematical rules
    always_ff @(posedge clk) begin
        
        // Proof 1: Reset Check
        if (!rst_n) begin
            a_reset: assert (signal_out == 1'b0 && sample_cnt == 2'd0);
        end

        // Functional Proofs (Only evaluate when system is active and running)
        if (rst_n && f_past_valid) begin

            // Proof 2: Counter Progression Sequence (0->1->2->3)
            if ($past(sample_cnt) < 2'd3) begin
                a_counter_sequence: assert (sample_cnt == $past(sample_cnt) + 1'b1);
            end

            // Proof 3: Counter Rollover Bound (3->0)
            if ($past(sample_cnt) == 2'd3) begin
                a_counter_rollover: assert (sample_cnt == 2'd0);
            end

            // Proof 4: Output Stability / No Toggling (Locked on counts 0, 1, 2)
            if ($past(sample_cnt) != 2'd3) begin
                a_stable_during_count: assert ($stable(signal_out));
            end

            // Proof 5: Correct Terminal Data Sampling (Latching input at count 3)
            if ($past(sample_cnt) == 2'd3) begin
                a_correct_sample_value: assert (signal_out == $past(signal_in));
            end
            
        end
    end

endmodule

// Bind the checker package directly to the main hardware block
bind signal_divider_by_4 signal_divider_by_4_formal i_signal_divider_by_4_formal (
    .clk(clk),
    .rst_n(rst_n),
    .signal_in(signal_in),
    .signal_out(signal_out),
    .sample_cnt(sample_cnt)
);

`default_nettype wire
`endif
