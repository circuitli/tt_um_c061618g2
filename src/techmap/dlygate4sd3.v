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

`ifndef DLYGATE4SD3_V
`define DLYGATE4SD3_V

`include "src/techmap/inv_1.v"
`include "src/techmap/buf_4.v"

`default_nettype none

module dlygate4sd3 (
    input wire A,
    output wire X
);
`ifdef IHP_SG13G2

    // ---------------------------------------------------------------------
    // HIGH-EFFICIENCY CAPACITIVE-LOADED INVERTER PAIR (~1.2 - 1.8 ns)
    // ---------------------------------------------------------------------
    (* keep = "true" *) wire internal_inv_node;
    (* keep = "true" *) wire scalar_cap_a;
    (* keep = "true" *) wire scalar_cap_b;

    // --- FIRST HALF STAGE ---
    (* keep = "true" *)
    inv_1 u_inv_a (
        .A (A),
        .Y (internal_inv_node)
    );
    
    // Attached gate-capacitance anchor 
    (* keep = "true" *)
    buf_4 u_load_cap_a (
        .A (internal_inv_node),
        .X (scalar_cap_a) 
    );

    // --- SECOND HALF STAGE (Restores Logic Phase Alignment) ---
    (* keep = "true" *)
    inv_1 u_inv_b (
        .A (internal_inv_node),
        .Y (X)
    );

    // Attached gate-capacitance anchor
    (* keep = "true" *)
    buf_4 u_load_cap_b (
        .A (X),
        .X (scalar_cap_b) 
    );

`elsif SKY130
    sky130_fd_sc_hd__dlygate4sd3 u_cell (.A(A), .X(X));
`elsif GF180MCU
    gf180mcu_fd_sc_7at__dlygate4sd3 u_cell (.A(A), .Y(X));
`else
    // Fallback behavioral assignment for local testbench verifications
    assign #1 X = A;
`endif
endmodule

`default_nettype wire
`endif