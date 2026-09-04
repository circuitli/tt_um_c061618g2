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
 
`ifndef AND2_1_V
`define AND2_1_V
`default_nettype none

// =========================================================================
// UNIVERSAL MULTI-PDK 2-INPUT AND GATE CELL ABSTRACTION LAYER (Drive 1)
// =========================================================================

module and2_1 (
    input wire A,   // Input operand A
    input wire B,   // Input operand B
    output wire Y   // Output (A AND B)
);
`ifdef IHP_SG13G2
    // IHP SG13G2 Open-Source 130nm AND2_1
    (* keep = "true" *) 
    sg13g2_and2_1 u_cell (
        .A(A), 
        .B(B), 
        .Y(Y)
    );
`elsif SKY130
    // SkyWater Sky130 High-Density AND2_1
    (* keep = "true" *) 
    sky130_fd_sc_hd__and2_1 u_cell (
        .A(A), 
        .B(B), 
        .X(Y) // Maps SkyWater's internal X output port to top level Y
    );
`elsif GF180MCU
    // GlobalFoundries GF180MCU 7-track 5V AND2_1
    (* keep = "true" *) 
    gf180mcu_fd_sc_mcu7t5v0__and2_1 u_cell (
        .I0(A), // GF naming convention uses I0/I1 for logic gate inputs
        .I1(B), 
        .Z(Y)   // Maps GF's internal Z output port to top level Y
    );
`else
    // Pure behavioral fallback for local verification (Icarus / Verilator / Cocotb)
    assign Y = A & B;
`endif
endmodule

`default_nettype wire
`endif
