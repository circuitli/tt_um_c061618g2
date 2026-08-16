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

`ifndef TT_ANTI_GLITCH_FILTER_FORMAL_SV
`define TT_ANTI_GLITCH_FILTER_FORMAL_SV
 
`default_nettype none

module tt_anti_glitch_filter_formal (
    input wire clk,
    input wire rst_n,
    input wire raw_signal_in,
    input wire clean_signal_out
);

    // =========================================================================
    // PAST CYCLE VALIDITY TRACKING
    // =========================================================================
    logic f_past_valid = 1'b0;

    always_ff @(posedge clk) begin
        f_past_valid <= 1'b1;
    end

    // =========================================================================
    // FORMAL ASSERTIONS ENGINE (Aligned with Sequential Implementation)
    // =========================================================================
    always_ff @(posedge clk) begin
        // 1. Asynchronous Reset Validation
        if (!rst_n) begin
            assert_reset_output: assert (clean_signal_out == 1'b1);
        end 
        
        // 2. Synchronous Functional Path Evaluation
        else if (f_past_valid && $past(rst_n)) begin
            
            // Assert Active-Low Filter Cleared (Delayed by 1 cycle due to output register)
            if ($past(shift_reg) == 2'b00) begin
                assert_filter_low: assert (clean_signal_out == 1'b0);
            end
            
            // Assert Idle-High Filter Restored (Delayed by 1 cycle due to output register)
            if ($past(shift_reg) == 2'b11) begin
                assert_filter_high: assert (clean_signal_out == 1'b1);
            end

            // 3. Glitch Rejection Multi-Cycle Stability Proofs
            // If the filter output was low, a transient high pulse lasting only 1 cycle must be rejected
            if ($past(clean_signal_out, 2) == 1'b0 && 
                $past(raw_signal_in, 2)    == 1'b0 && 
                $past(raw_signal_in, 1)    == 1'b1 && 
                raw_signal_in              == 1'b0) begin
                assert_glitch_high_rejected: assert (clean_signal_out == 1'b0);
            end

            // If the filter output was high, a transient low pulse lasting only 1 cycle must be rejected
            if ($past(clean_signal_out, 2) == 1'b1 && 
                $past(raw_signal_in, 2)    == 1'b1 && 
                $past(raw_signal_in, 1)    == 1'b0 && 
                raw_signal_in              == 1'b1) begin
                assert_glitch_low_rejected: assert (clean_signal_out == 1'b1);
            end
            
        end
    end

endmodule

// =========================================================================
// BIND DIRECTIVE: Inject properties cleanly into production RTL target
// =========================================================================
bind tt_anti_glitch_filter tt_anti_glitch_filter_formal i_tt_anti_glitch_filter_formal (
    .clk              (clk),
    .rst_n            (rst_n),
    .raw_signal_in    (raw_signal_in),
    .clean_signal_out (clean_signal_out),
    .shift_reg        (shift_reg)
);

`endif

