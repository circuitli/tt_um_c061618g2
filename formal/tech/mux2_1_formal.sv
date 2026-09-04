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

`ifndef MUX2_1_FORMAL_SV
`define MUX2_1_FORMAL_SV
`default_nettype none

module mux2_1_formal (
    input wire A0,
    input wire A1,
    input wire S,
    input wire Y
);

    // =========================================================================
    // UNCLOCKED COMBINATIONAL FORMAL PROPERTIES
    // =========================================================================
    always_comb begin
        // Property 1: When select line S is low, output Y must match input A0
        if (!S) begin
            assert_select_a0: assert (Y == A0);
        end

        // Property 2: When select line S is high, output Y must match input A1
        if (S) begin
            assert_select_a1: assert (Y == A1);
        end

        // Property 3: Safety logic equivalence equation mapping
        assert_boolean_equivalence: assert (Y == (S ? A1 : A0));
    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind mux2_1 mux2_1_formal i_mux2_1_formal (
    .A0(A0),
    .A1(A1),
    .S(S),
    .Y(Y)
);

`default_nettype wire
`endif