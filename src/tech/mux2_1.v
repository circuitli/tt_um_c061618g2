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

`ifndef MUX2_1_V
`define MUX2_1_V
`default_nettype none

// =========================================================================
// UNIVERSAL MULTI-PDK 2-to-1 MULTIPLEXER CELL ABSTRACTION LAYER 
// =========================================================================

module mux2_1 (
    input wire A0,  // Data input selected when S = 0
    input wire A1,  // Data input selected when S = 1
    input wire S,   // Select line
    output wire Y   // Output
);
`ifdef IHP_SG13G2
    // IHP SG13G2 Open-Source 130nm MUX2_1
    sg13g2_mux2_1 u_cell (
        .A0(A0), 
        .A1(A1), 
        .S(S), 
        .Y(Y)
    );
`elsif SKY130
    // SkyWater Sky130 High-Density MUX2_1
    sky130_fd_sc_hd__mux2_1 u_cell (
        .A0(A0), 
        .A1(A1), 
        .S(S), 
        .X(Y) // Maps SkyWater's internal X output port to top level Y
    );
`elsif GF180MCU
    // GlobalFoundries GF180MCU 7-track 5V MUX2_1
    gf180mcu_fd_sc_mcu7t5v0__mux2_1 u_cell (
        .I0(A0), // GF naming convention uses I0/I1 for data inputs
        .I1(A1), 
        .S(S), 
        .Z(Y)    // Maps GF's internal Z output port to top level Y
    );
`else
    // Pure behavioral fallback for local verification (Icarus / Verilator)
    assign Y = S ? A1 : A0;
`endif
endmodule

`default_nettype wire
`endif