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

`ifndef AOI21_1_FORMAL_SV
`define AOI21_1_FORMAL_SV
`default_nettype none

// =========================================================================
// SYSTEMVERILOG FORMAL PROPERTIES FOR COMPLEX AOI COMBINATIONAL LAYER
// =========================================================================

module aoi21_1_formal (
    input wire A1,
    input wire A2,
    input wire B1,
    input wire Y
);

    // ---------------------------------------------------------------------
    // FORMAL ASSERTION: Complete Boolean Combinational Verification
    // ---------------------------------------------------------------------
    // Mathematically enforce that the cell output perfectly mirrors the 
    // structural AOI21 Boolean truth function: Y = ~((A1 & A2) | B1)
    property p_aoi21_logic_matrix;
        (Y == !((A1 && A2) || B1));
    endproperty

    assert_boolean_truth_table: assert property (p_aoi21_logic_matrix);

    // ---------------------------------------------------------------------
    // OPERATIONAL COVERAGE METRICS
    // ---------------------------------------------------------------------
    // Ensure all branches of the combined gate equation are fully reachable
    cover_aoi_inverted:   cover property (!Y);
    cover_aoi_pass_thru:  cover property (Y);

endmodule


// =========================================================================
// SYSTEMVERILOG FORMAL VERIFICATION BIND FOOTPRINT
// =========================================================================
bind aoi21_1 aoi21_1_formal u_formal_aoi_checks (
    .A1(A1),
    .A2(A2),
    .B1(B1),
    .Y(Y)
);

`default_nettype wire
`endif 