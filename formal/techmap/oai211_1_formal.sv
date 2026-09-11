`ifndef OAI211_1_FORMAL_SV
`define OAI211_1_FORMAL_SV

`include "src/techmap/oai211_1.v"

`default_nettype none

module oai211_1_formal (
    input wire A1,
    input wire A2,
    input wire B1,
    input wire C1,
    input wire Y
);

    // =========================================================================
    // STATIC UNCLOCKED COMBINATIONAL PROPERTIES
    // =========================================================================
    always_comb begin
        
        // ---------------------------------------------------------------------
        // PROPERTY 1: Golden Model Logic Equivalence
        // ---------------------------------------------------------------------
        // Verifies that the physical cell output 'Y' perfectly matches the 
        // mathematical OAI211 standard function: Y = !((A1 || A2) && B1 && C1)
        assert_logic_equivalence: assert (Y == !((A1 || A2) && B1 && C1));

        // ---------------------------------------------------------------------
        // PROPERTY 2: Dual Term Invalidation (OR Branch Dominance)
        // ---------------------------------------------------------------------
        // If both inputs to the internal OR gate are low (A1=0 and A2=0), the 
        // entire internal AND product drops to 0. Due to the output inversion, 
        // 'Y' must be driven hard high (1'b1) regardless of the B1 and C1 rails.
        assert_or_branch_disabled: assert ((A1 || A2) || (Y == 1'b1));

        // ---------------------------------------------------------------------
        // PROPERTY 3: Product Disabling (Direct Clear/Mask Dominance)
        // ---------------------------------------------------------------------
        // If either of the independent direct serial terms (B1 or C1) drops to low,
        // the internal product updates to 0. The output 'Y' must latch high (1'b1).
        assert_and_product_disabled: assert ((B1 && C1) || (Y == 1'b1));

        // =====================================================================
        // OPERATIONAL COVERAGE METRICS
        // =====================================================================
        cover_output_high: cover (Y == 1'b1);
        cover_output_low:  cover (Y == 1'b0);

    end

endmodule

// =========================================================================
// BIND STATEMENT FOR AUTOMATED INTERCEPTION
// =========================================================================
// Intercepts the universal wrapper target name cleanly
bind oai211_1 oai211_1_formal i_oai211_1_formal (
    .A1(A1),
    .A2(A2),
    .B1(B1),
    .C1(C1),
    .Y(Y)
);

`default_nettype wire
`endif
