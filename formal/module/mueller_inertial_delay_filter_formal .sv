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

module mueller_inertial_delay_filter_formal (
    input wire in,
    input wire out,
    input wire delayed_path,
    input wire c_element_out
);

    // ---------------------------------------------------------------------
    // PROPERTY 1: Inertial Glitch Filtering Action
    // ---------------------------------------------------------------------
    // If the input changes state but toggles back before the internal delay path 
    // updates, the consensus latch must reject the change and remain completely locked.
    property p_glitch_suppression;
        disable iff (in == delayed_path)
        (out == $past(out));
    endproperty

    assert_glitch_filter: assert property (p_glitch_suppression);

    // ---------------------------------------------------------------------
    // PROPERTY 2: Steady-State Phase Invariant
    // ---------------------------------------------------------------------
    // Once the internal delay path has caught up with the input signal state,
    // the output must perfectly match the logical polarity of the input.
    property p_steady_state_lock;
        (in == delayed_path) -> (out == in);
    endproperty

    assert_steady_state_lock: assert property (p_steady_state_lock);

    // ---------------------------------------------------------------------
    // PROPERTY 3: Asynchronous Safety Boundary (No Illegal Interstates)
    // ---------------------------------------------------------------------
    // It is physically impossible for the internal feedback node and the 
    // filtered output node to settle on identical logic phases under stable rails.
    property p_feedback_safety;
        (c_element_out != out);
    endproperty

    assert_feedback_phase_safety: assert property (p_feedback_safety);

    // ---------------------------------------------------------------------
    // OPERATIONAL COVERAGE METRICS
    // ---------------------------------------------------------------------
    // Verify that both valid high and low structural paths remain completely 
    // reachable within the solver bounds without deadlocking the loop.
    cover_transit_high: cover property (in && out);
    cover_transit_low:  cover property (!in && !out);

endmodule


// =========================================================================
// SYSTEMVERILOG FORMAL VERIFICATION BIND FOOTPRINT
// =========================================================================

// Binds the checking rules directly onto the clockless target module
bind mueller_inertial_delay_filter mueller_inertial_delay_filter_formal i_mueller_inertial_delay_filter_formal (
    .in(in),
    .out(out),
    .delayed_path(delayed_path),
    .c_element_out(c_element_out);

`default_nettype wire
`endif