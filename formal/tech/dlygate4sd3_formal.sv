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
`default_nettype none

// =========================================================================
// SYSTEMVERILOG FORMAL PROPERTIES FOR UNIVERSAL DELAY GAP
// =========================================================================

module dlygate4sd3_formal (
    input wire A,
    input wire X
);

    // ---------------------------------------------------------------------
    // FORMAL ASSERTION: Non-Inverting Path Preservation Invariant
    // ---------------------------------------------------------------------
    // The delay macro behaves natively as a single-stage buffer flag tracking line.
    // Under stable DC conditions, the output state must track the source pin phase.
    property p_buffer_equivalence;
        (A == X);
    endproperty

    assert_propagation_phase: assert property (p_buffer_equivalence);

    // ---------------------------------------------------------------------
    // OPERATIONAL COVERAGE METRICS
    // ---------------------------------------------------------------------
    cover_state_high: cover property (A && X);
    cover_state_low:  cover property (!A && !X);

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