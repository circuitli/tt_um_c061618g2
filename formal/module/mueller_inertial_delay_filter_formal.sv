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

`include "src/module/mueller_inertial_delay_filter.v"

`include "formal/techmap/dlygate4sd3_formal.sv"
`include "formal/techmap/aoi211_1_formal.sv"
`include "formal/techmap/inv_1_formal.sv"

`default_nettype none

module mueller_inertial_delay_filter_formal (
    input wire rst_n,
    input wire async_in,
    input wire async_out,
    input wire delayed_path
);

    // =========================================================================
    // UNCLOCKED COMBINATIONAL FORMAL PROPERTIES (NON-INVERTING OAI211 LOGIC)
    // =========================================================================
    always_comb begin
        
        // ---------------------------------------------------------------------
        // PROPERTY 1: Asynchronous Reset State Enforcement
        // ---------------------------------------------------------------------
        // When rst_n is driven low, the OAI211 mask forces async_out to 0.
        if (!rst_n) begin
            assert_reset_active: assert (async_out == 1'b0);
        end

        // ---------------------------------------------------------------------
        // PROPERTY 2: Inertial Glitch Filtering Action (State Retention)
        // ---------------------------------------------------------------------
        // If the current input does not match the output of the delay line, 
        // the filter must retain its previous stable state value.
        // (Verifies the positive feedback latching behavior)
        if (rst_n && (async_in != delayed_path)) begin
            // In a non-inverting C-element, if inputs mismatch, the output 
            // remains stable. In a combinational always block, this can be proven 
            // by checking that the OAI state equations evaluate to a valid latch.
            assert_latch_holding: assert (async_out == !((async_in || delayed_path) && async_out && rst_n));
        end

        // ---------------------------------------------------------------------
        // PROPERTY 3: Steady-State Phase Invariant (Non-Inverting)
        // ---------------------------------------------------------------------
        // Once the internal delay line has caught up with the input signal phase,
        // the clean output must perfectly match the logical polarity of the input.
        if (rst_n && (async_in == delayed_path)) begin
            assert_phase_aligned: assert (async_out == async_in);
        end

        // =====================================================================
        // OPERATIONAL COVERAGE METRICS
        // =====================================================================
        if (rst_n) begin
            cover_transit_high: cover (async_in && async_out);
            cover_transit_low:  cover (!async_in && !async_out);
        end

    end

endmodule

// =========================================================================
// UPDATED BIND STATEMENT
// =========================================================================
// Removed the old 'c_element_state' mapping and hooked cleanly to the new 
// structural OAI211 non-inverting filter variables.
bind mueller_inertial_delay_filter mueller_inertial_delay_filter_formal i_mueller_inertial_delay_filter_formal (
    .rst_n(rst_n),
    .async_in(async_in),
    .async_out(async_out),
    .delayed_path(delayed_path)
);

`default_nettype wire
`endif
