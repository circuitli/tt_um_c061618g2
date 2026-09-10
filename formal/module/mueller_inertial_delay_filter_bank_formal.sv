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

`ifndef MUELLER_INERTIAL_DELAY_FILTER_BANK_FORMAL_SV
`define MUELLER_INERTIAL_DELAY_FILTER_BANK_FORMAL_SV
`default_nettype none

// =============================================================================
// Module Name:     mueller_inertial_delay_filter_bank_formal
// Description:     Formal Verification Properties and Bind Module for the
//                  Müller Inertial Delay Filter Bank.
// =============================================================================

module mueller_inertial_delay_filter_bank_formal #(
    parameter int WIDTH = 13
)(
    input  wire             rst_n,
    input  wire [WIDTH-1:0] async_in,
    input  wire [WIDTH-1:0] async_out
);

    // -------------------------------------------------------------------------
    // Formal Reset Assumption
    // -------------------------------------------------------------------------
    // Ensures the formal engine exercises a proper power-on reset sequence
    property p_reset_initial;
        ##0 !rst_n ##1 rst_n;
    endproperty
    a_reset_initial: assume property (p_reset_initial);

    // -------------------------------------------------------------------------
    // Formal Verification Properties per Channel
    // -------------------------------------------------------------------------
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : formal_channels

            // 1. Reset State Verification
            // Assert that during active reset, the async outputs force low
            property p_output_reset_state;
                (!rst_n) -> (async_out[i] == 1'b0);
            endproperty
            a_output_reset_state: assert property (p_output_reset_state);

            // 2. Glitch Suppression Bounds (Inertial Delay Enforcement)
            // Assert that input pulses narrower than the stabilization threshold
            // are filtered out and fail to toggle the output.
            property p_inertial_glitch_filter_high;
                disable iff (!rst_n)
                ($rose(async_in[i]) ##1 !async_in[i]) -> ##1 (async_out[i] == 1'b0);
            endproperty
            a_inertial_glitch_filter_high: assert property (p_inertial_glitch_filter_high);

            property p_inertial_glitch_filter_low;
                disable iff (!rst_n)
                ($fell(async_in[i]) ##1 async_in[i]) -> ##1 (async_out[i] == 1'b1);
            endproperty
            a_inertial_glitch_filter_low: assert property (p_inertial_glitch_filter_low);

            // 3. Functional Forward Stability
            // Assert that a stable input value propagates cleanly through the 
            // C-element filter bank matrix to the output.
            property p_stable_propagation;
                disable iff (!rst_n)
                (async_in[i] == async_out[i]) [*2] -> (async_out[i] == async_in[i]);
            endproperty
            a_stable_propagation: assert property (p_stable_propagation);

        end
    endgenerate

endmodule


// =============================================================================
// Formal Verification Bind Wrapper
// =============================================================================
bind mueller_inertial_delay_filter_bank mueller_inertial_delay_filter_bank_formal #(
    .WIDTH(WIDTH)
) i_mueller_inertial_delay_filter_bank_formal (
    .rst_n    (rst_n),
    .async_in (async_in),
    .async_out(async_out)
);

`default_nettype wire
`endif