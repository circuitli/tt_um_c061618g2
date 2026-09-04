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

`ifndef AOI21_1_V
`define AOI21_1_V
`default_nettype none

module aoi21_1 (
    input wire A1,
    input wire A2,
    input wire B1,
    output wire Y
);
`ifdef IHP_SG13G2
    (* keep = "true" *) sg13g2_aoi21_1 u_cell (.A1(A1), .A2(A2), .B1(B1), .Y(Y));
`elsif SKY130
    (* keep = "true" *) sky130_fd_sc_hd__aoi21_1 u_cell (.A1(A1), .A2(A2), .B1(B1), .Y(Y));
`elsif GF180MCU
    (* keep = "true" *) gf180mcu_fd_sc_7at__aoi21_1 u_cell (.A1(A1), .A2(A2), .B1(B1), .Y(Y));
`else
    // Fallback behavioral modeling for Verilator/Icarus simulators
    assign Y = !((A1 && A2) || B1);
`endif
endmodule

`default_nettype wire
`endif
