
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

`ifndef BUF_4_FORMAL_SV
`define BUF_4_FORMAL_SV
`default_nettype none

module buf_4_formal (
    input wire A,
    input wire X
);

    // =========================================================================
    // UNCLOCKED COMBINATIONAL FORMAL PROPERTIES
    // =========================================================================
    always_comb begin
        // Property 1: Output X must strictly track input A immediately
        assert_buffer_tracking: assert (X == A);
    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind buf_4 buf_4_formal i_buf_4_formal (
    .A(A),
    .X(X)
);

`default_nettype wire
`endif