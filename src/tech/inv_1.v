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

`ifndef INV_1_V
`define INV_1_V
`default_nettype none

// =========================================================================
// UNIVERSAL MULTI-PDK INVERTER CELL ABSTRACTION LAYER (Drive Strength 1)
// =========================================================================

module inv_1 (
    input wire A,
    output wire Y
);
`ifdef IHP_SG13G2
    // IHP SG130G2 Standard Density Inverter
    (* keep = "true" *) sg13g2_inv_1 u_cell (.A(A), .Y(Y));
`elsif SKY130
    // SkyWater Sky130 High-Density Inverter
    (* keep = "true" *) sky130_fd_sc_hd__inv_1 u_cell (.A(A), .Y(Y));
`elsif GF180MCU
    // GlobalFoundries GF180MCU 7-track Inverter
    (* keep = "true" *) gf180mcu_fd_sc_7at__inv_1 u_cell (.A(A), .Y(Y));
`else
    // Pure behavioral fallback for local verification (Icarus / Verilator)
    assign Y = !A;
`endif
endmodule

`default_nettype wire
`endif
