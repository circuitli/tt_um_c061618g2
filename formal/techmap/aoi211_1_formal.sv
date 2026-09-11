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

`ifndef AOI211_1_FORMAL_SV
`define AOI211_1_FORMAL_SV

`include "src/techmap/aoi21_1.v"

`default_nettype none

module aoi211_1_formal (
    input wire A1,
    input wire A2,
    input wire B1,
    input wire C1,
    input wire Y
);

    // =========================================================================
    // STATIC UNCLOCKED COMBINATIONAL PROPERTIES
    // =========================================================================

    always @* begin
        
        // ---------------------------------------------------------------------
        // PROPERTY 1: Golden Model Logic Equivalence
        // ---------------------------------------------------------------------
        // Verifies that whatever internal gates are instantiated by the active 
        // PDK branch, the physical output 'Y' matches the target mathematical 
        // definition perfectly across all input states.
        assert_logic_equivalence: assert (Y == !((A1 && A2) || B1 || C1));

        // ---------------------------------------------------------------------
        // PROPERTY 2: Product Term Invalidation (AND branch dominance)
        // ---------------------------------------------------------------------
        // If either input to the product gate branch is low, the (A1 & A2) term 
        // drops to 0, making the output purely dependent on the B1 and C1 rails.
        // Rewritten from: (!A1 || !A2) -> (Y == !(B1 || C1))
        // Using Boolean identity: (!P || Q) => (A1 && A2) || Q
        assert_product_disabled: assert ((A1 && A2) || (Y == !(B1 || C1)));

        // ---------------------------------------------------------------------
        // PROPERTY 3: Safe Static Clear / Mask Dominance
        // ---------------------------------------------------------------------
        // If either of the independent direct-input terms (B1 or C1) is driven 
        // high, the entire inner bracket evaluates to true. Because it is an inverted 
        // gate, the output 'Y' must be driven hard to 0 regardless of the 'A' branch states.
        // Rewritten from: (B1 || C1) -> (Y == 1'b0)
        // Using Boolean identity: (!P || Q) => !(B1 || C1) || Q
        assert_mask_dominance: assert (!(B1 || C1) || (Y == 1'b0));

        // =====================================================================
        // SYSTEM COVERS: Ensure all boolean exit states are reachable
        // =====================================================================
        cover_output_high: cover (Y == 1'b1);
        cover_output_low:  cover (Y == 1'b0);

    end

endmodule

// =========================================================================
// BIND STATEMENT FOR AUTOMATED INTERCEPTION
// =========================================================================
// Ties this verification block directly into the universal wrapper instance.
bind aoi211_1 aoi21_1_formal i_aoi21_1_formal (
    .A1(A1),
    .A2(A2),
    .B1(B1),
    .C1(C1),
    .Y(Y)
);

`default_nettype wire
`endif