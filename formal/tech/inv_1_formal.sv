
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

`ifndef INV_1_FORMAL_SV
`define INV_1_FORMAL_SV
`default_nettype none

module inv_1_formal (
    input wire A,
    input wire Y
);

    // =========================================================================
    // UNCLOCKED COMBINATIONAL FORMAL PROPERTIES
    // =========================================================================
    always_comb begin
        // Property 1: The output Y must never equal the input A
        assert_inversion_state: assert (Y != A);

        // Property 2: Strictly functional boolean inversion tracking
        assert_boolean_logic: assert (Y == ~A);
    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind inv_1 inv_1_formal i_inv_1_formal (
    .A(A),
    .Y(Y)
);

`default_nettype wire
`endif
