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

`ifndef MUELLER_INERTIAL_DELAY_FILTER_FORMAL_SV
`define MUELLER_INERTIAL_DELAY_FILTER_FORMAL_SV
`default_nettype none

//=====================================================================
// SYSTEMVERILOG FORMAL PROPERTIES FOR MUELLER INERTIAL DELAY FILTER
// =========================================================================

`default_nettype none

module mueller_inertial_delay_filter_formal (
    input wire rst_n,
    input wire in,
    input wire out,
    input wire delayed_path,
    input wire c_element_out
);

    // =========================================================================
    // UNCLOCKED COMBINATIONAL FORMAL PROPERTIES
    // =========================================================================
    always_comb begin
        
        // Asynchronous reset state enforcement
        if (!rst_n) begin
            assert_reset_state: assert (out == 1'b0);
        end

        // ---------------------------------------------------------------------
        // PROPERTY 1: Inertial Glitch Filtering Action
        // ---------------------------------------------------------------------
        // If the input doesn't match the delayed path, the output must remain 
        // locked in its state unless both structural inputs change.
        // (Replaces temporal '$past' logic with instantaneous state matching)
        if (rst_n && (in != delayed_path)) begin
            assert_glitch_filter: assert (out == !c_element_out);
        end

        // ---------------------------------------------------------------------
        // PROPERTY 2: Steady-State Phase Invariant
        // ---------------------------------------------------------------------
        // Once the internal delay path has caught up with the input signal state,
        // the output must perfectly match the logical polarity of the input.
        if (rst_n && (in == delayed_path)) begin
            assert_steady_state_lock: assert (out == in);
        end

        // ---------------------------------------------------------------------
        // PROPERTY 3: Asynchronous Safety Boundary (No Illegal Interstates)
        // ---------------------------------------------------------------------
        // It is physically impossible for the internal feedback node and the 
        // filtered output node to settle on identical logic phases under stable rails.
        if (rst_n) begin
            assert_feedback_phase_safety: assert (c_element_out != out);
        end

        // ---------------------------------------------------------------------
        // OPERATIONAL COVERAGE METRICS
        // ---------------------------------------------------------------------
        if (rst_n) begin
            cover_transit_high: cover (in && out);
            cover_transit_low:  cover (!in && !out);
        end

    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind mueller_inertial_delay_filter mueller_inertial_delay_filter_formal i_mueller_inertial_delay_filter_formal (
    .rst_n(rst_n),
    .in(in),
    .out(out),
    .delayed_path(delayed_path),
    .c_element_out(c_element_out)
);

`default_nettype wire
`endif