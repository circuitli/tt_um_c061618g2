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

`ifndef ANTI_GLITCH_FILTER_FORMAL_SV
`define ANTI_GLITCH_FILTER_FORMAL_SV
 
`default_nettype none

// 1. Remove the parameter list from the module header completely
module anti_glitch_filter_formal (
    input wire clk,
    input wire rst_n,
    input wire TESTMODE_n,
    input wire raw_signal_in,
    input wire clean_signal_out
);

    // 2. Declare an unconstrained formal tracking register
    // SymbiYosys will automatically test BOTH 0 and 1 paths simultaneously!
    (* formal_anyconst *) reg formal_active_low;
    
    // Dynamic parameterization evaluates seamlessly without synthesis errors
    wire safe_state;
    assign safe_state = formal_active_low ? 1'b1 : 1'b0;

    // =========================================================================
    // PAST CYCLE VALIDITY TRACKING
    // =========================================================================
    wire f_past_valid = 1'b0;

    always_ff @(posedge clk) begin
        f_past_valid <= 1'b1;
    end

    // =========================================================================
    // COMBINATIONAL INVARIANT (TESTMODE Bypass Path Audit matching parallel RTL)
    // =========================================================================
    always_comb begin
        if (!TESTMODE_n) begin
            assert_dft_bypass_path: assert (clean_signal_out == safe_state);
        end
    end

    // =========================================================================
    // FORMAL ASSERTIONS ENGINE (Functional Mode when !TESTMODE)
    // =========================================================================
    always_ff @(posedge clk) begin
        if (TESTMODE_n) begin
            // 1. Asynchronous Reset Validation
            if (!rst_n) begin
                assert_reset_output: assert (clean_signal_out == safe_state);
            end 
            
            // 2. Synchronous Functional Path Evaluation (Timed to Interleaved 2.5 cycles)
            else if (f_past_valid && $past(rst_n)) begin
                
                // 3. Glitch Rejection Multi-Cycle Stability Proofs
                if ($past(clean_signal_out, 2) == 1'b0 && 
                    $past(raw_signal_in, 2)    == 1'b0 && 
                    $past(raw_signal_in, 1)    == 1'b1 && 
                    raw_signal_in              == 1'b0) begin
                    assert_glitch_high_rejected: assert (clean_signal_out == 1'b0);
                end

                if ($past(clean_signal_out, 2) == 1'b1 && 
                    $past(raw_signal_in, 2)    == 1'b1 && 
                    $past(raw_signal_in, 1)    == 1'b0 && 
                    raw_signal_in              == 1'b1) begin
                    assert_glitch_low_rejected: assert (clean_signal_out == 1'b1);
                end
                
            end
        end
    end

endmodule

bind anti_glitch_filter anti_glitch_filter_formal i_anti_glitch_filter_formal (
    .clk              (clk),
    .rst_n            (rst_n),
    .TESTMODE_n       (TESTMODE_n), 
    .raw_signal_in    (raw_signal_in),
    .clean_signal_out (clean_signal_out)
);

`default_nettype wire
`endif // ANTI_GLITCH_FILTER_FORMAL_SV

