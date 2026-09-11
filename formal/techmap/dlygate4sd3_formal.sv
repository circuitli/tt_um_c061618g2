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

`ifndef DLYGATE4SD3_FORMAL_SV
`define DLYGATE4SD3_FORMAL_SV

`include "src/techmap/dlygate4sd3.v"

`include "formal/techmap/inv_1_formal.sv"
`include "formal/techmap/buf_4_formal.sv"

`default_nettype none

// =========================================================================
// SYSTEMVERILOG FORMAL PROPERTIES FOR UNIVERSAL DELAY GAP
// =========================================================================

module dlygate4sd3_formal (
    input wire A,
    input wire X
);

    // ---------------------------------------------------------------------
    // UNIVERSAL STARTUP STATE DETECTOR (Tool-Agnostic Equivalent)
    // ---------------------------------------------------------------------
    // An uninitialized register defaults to 1'b1 under formal evaluation 
    // rules, then falls to 1'b0 on the first unclocked evaluation tick.
    reg f_initstate = 1'b1;
    always_comb begin
        f_initstate = 1'b0;
    end

    // ---------------------------------------------------------------------
    // COMBINATORIAL ASYNCHRONOUS ASSERTIONS
    // ---------------------------------------------------------------------
    always_comb begin
        if (!f_initstate) begin
            // Non-Inverting Path Preservation Invariant:
            // Validates that under steady-state conditions, the output matches
            // the input exactly across all target PDK variants.
            assert_propagation_phase: assert (A == X);
        end
    end

    // ---------------------------------------------------------------------
    // OPERATIONAL COVERAGE METRICS
    // ---------------------------------------------------------------------
    always_comb begin
        if (!f_initstate) begin
            if (A && X)   cover_state_high: cover (1'b1);
            if (!A && !X) cover_state_low:  cover (1'b1);
        end
    end

endmodule


// =========================================================================
// SYSTEMVERILOG FORMAL VERIFICATION BIND FOOTPRINT
// =========================================================================
bind dlygate4sd3 dlygate4sd3_formal i_dlygate4sd3_formal (
    .A(A),
    .X(X)
);

`default_nettype wire
`endif 