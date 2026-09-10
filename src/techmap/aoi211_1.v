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

`ifndef AOI211_1_V
`define AOI211_1_V
`default_nettype none

// =========================================================================
// UNIVERSAL CROSS-PDK TECHMAP: MAPPING "AOI211_1" UNTO ACTUAL SILICON
// =========================================================================

module aoi211_1 (
    input  wire A1,
    input  wire A2,
    input  wire B1,
    input  wire C1,
    output wire Y
);

`ifdef IHP_SG13G2
    // Actual IHP Library Map: Use the real AND-OR cell + an output inverter
    wire ao_combined_net;
    wire or_bracket_net;

    // 1. OR the feedback node (B1) and the reset trigger (C1) 
    sg13g2_or2_1 u_ihp_or (
        .A(B1),
        .B(C1),
        .X(or_bracket_net)
    );

    // 2. Map to the true, existing IHP AND-OR cell
    // Library Equation: X = (A1 & A2) | B1
    sg13g2_ao21_1 u_ihp_ao_core (
        .A1(A1),
        .A2(A2),
        .B1(or_bracket_net),
        .X(ao_combined_net)
    );

    // 3. Invert the result to complete the original AND-OR-Invert expression
    sg13g2_inv_1 u_ihp_output_inv (
        .A(ao_combined_net),
        .Y(Y)
    );

`elsif GF180MCU
    // GlobalFoundries HAS a native AOI211 cell footprint
    gf180mcu_fd_sc_mcu7t5v0__aoi211_1 u_gf_aoi (
        .I0(A1),
        .I1(A2),
        .I2(B1),
        .I3(C1),
        .Z(Y)
    );

`elsif SKY130
    // SkyWater Sky130 Native High-Density Library Cell
    sky130_fd_sc_hd__aoi211_1 u_sky_aoi (
        .A1(A1),
        .A2(A2),
        .B1(B1),
        .C1(C1),
        .Y(Y)
    );

`else
    // Pure behavioral fallback for local verification (Icarus / Verilator)
    assign Y = !((A1 && A2) || B1 || C1);
`endif

endmodule

`default_nettype wire
`endif