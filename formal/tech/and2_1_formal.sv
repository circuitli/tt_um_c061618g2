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

`include "src/tech/and2_1.v"

module and2_1_formal (
    input wire A,
    input wire B,
    input wire X
);

    // =========================================================================
    // CLOCKLESS CONTEXT FOR SYMBIVOSYS
    // =========================================================================
    always @* begin
        // Property 1: Boolean equivalence equation mapping
        assert (X == (A & B));

        // Property 2: Low Dominance using pure boolean Or identity
        assert ((A && B) || (X == 1'b0));

        // Property 3: High Condition using pure boolean Or identity
        assert (!(A && B) || (X == 1'b1));
    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind and2_1 and2_1_formal i_and2_1_formal (
    .A(A),
    .B(B),
    .X(X)
);

`default_nettype wire
`endif
