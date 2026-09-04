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

`ifndef AND2_1_FORMAL_SV
`define AND2_1_FORMAL_SV
`default_nettype none

module and2_1_formal (
    input wire A,
    input wire B,
    input wire Y
);

    // =========================================================================
    // UNCLOCKED COMBINATIONAL FORMAL PROPERTIES
    // =========================================================================
    always_comb begin
        // Property 1: If either input is low, output Y must be low
        if (!A || !B) begin
            assert_low_dominance: assert (Y == 1'b0);
        end

        // Property 2: If both inputs are high, output Y must be high
        if (A && B) begin
            assert_high_condition: assert (Y == 1'b1);
        end

        // Property 3: Safety logic equivalence equation mapping
        assert_boolean_equivalence: assert (Y == (A & B));
    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind and2_1 and2_1_formal u_and2_1_fv (
    .A(A),
    .B(B),
    .Y(Y)
);

`default_nettype wire
`endif
