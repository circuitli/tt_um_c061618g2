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

`default_nettype none

//=====================================================================
// SYSTEMVERILOG FORMAL PROPERTIES FOR MUELLER INERTIAL DELAY FILTER
// =========================================================================

module mueller_inertial_delay_filter_formal (
    input wire rst_n,
    input wire async_in,
    input wire async_out,
    input wire delayed_path,
    input wire c_element_state
);

    // =========================================================================
    // UNCLOCKED COMBINATIONAL FORMAL PROPERTIES
    // =========================================================================
    always_comb begin
        
        // Asynchronous reset state enforcement
        if (!rst_n) begin
            assert (async_out == 1'b0);
        end

        // ---------------------------------------------------------------------
        // PROPERTY 1: Inertial Glitch Filtering Action
        // ---------------------------------------------------------------------
        // If the input doesn't match the delayed path, the output must remain 
        // locked in its state unless both structural inputs change.
        if (rst_n && (async_in != delayed_path)) begin
            assert (async_out == !c_element_state);
        end

        // ---------------------------------------------------------------------
        // PROPERTY 2: Steady-State Phase Invariant
        // ---------------------------------------------------------------------
        // Once the internal delay path has caught up with the input signal state,
        // the output must perfectly match the logical polarity of the input.
        if (rst_n && (async_in == delayed_path)) begin
            assert (async_out == async_in);
        end

        // ---------------------------------------------------------------------
        // PROPERTY 3: Asynchronous Safety Boundary (No Illegal Interstates)
        // ---------------------------------------------------------------------
        // It is physically impossible for the internal feedback node and the 
        // filtered output node to settle on identical logic phases under stable rails.
        if (rst_n) begin
            assert (c_element_state != async_out);
        end

        // ---------------------------------------------------------------------
        // OPERATIONAL COVERAGE METRICS
        // ---------------------------------------------------------------------
        if (rst_n) begin
            // Fixed the typo here from "in" -> "async_in"
            cover (async_in && async_out);
            cover (!async_in && !async_out);
        end

    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind mueller_inertial_delay_filter mueller_inertial_delay_filter_formal i_mueller_inertial_delay_filter_formal (
    .rst_n(rst_n),
    .async_in(async_in),          // Fixed typo from iasync_in -> async_in
    .async_out(async_out),
    .delayed_path(delayed_path),
    .c_element_state(c_element_state) // Aligned named pointer with parent wire
);

`default_nettype wire
`endif
