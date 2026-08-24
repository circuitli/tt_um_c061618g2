/*
 * Copyright 2026 circuitli (https://github.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://apache.org
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
`ifndef C061618G2_FORMAL_SV
`define C061618G2_FORMAL_SV

`default_nettype none
`include "src/defs/mmu_defs.sv"

// =============================================================================
// Top-Level Formal Verification Container: tt_um_c061618g2_formal
// =============================================================================
module tt_um_c061618g2_formal (
    input wire [7:0] ui_in,
    input wire [7:0] uo_out,
    input wire [7:0] uio_in,
    input wire [7:0] uio_out,
    input wire [7:0] uio_oe,
    input wire       ena,
    input wire       clk,
    input wire       rst_n
);

    // --- Architectural Environmental Assumptions ---
    assume_initial_reset: assume property (
        @(posedge clk) $initstate |-> (!rst_n && ui_in == 8'h00 && uio_in == 8'h00)
    );

    assume_system_enabled: assume property (
        @(posedge clk) !$initstate |-> (ena == 1'b1)
    );

    // =========================================================================
    // EXHAUSTIVE MEMORY DECODER MAPPING ASSERTIONS (RESTORED)
    // =========================================================================
    
    // 1. Operating System ROM Allocation ($F800 - $FFFF)
    wire is_os_space = (ui_in[4:0] == 5'b11111); // Upper address bits match
    assert_os_decode: assert property (
        @(posedge clk) (rst_n && ena && is_os_space && uio_in[0]) |-> (uo_out[2] == 1'b0 && uo_out[3] == 1'b0)
    );

    // 2. BASIC Interpreter Memory Map Allocation ($A000 - $BFFF)
    wire is_basic_space = (ui_in[4:3] == 2'b10); 
    assert_basic_decode: assert property (
        @(posedge clk) (rst_n && ena && is_basic_space && !uio_in[3] && uio_in[0]) |-> (uo_out[1] == 1'b0)
    );

    // 3. Peripheral Hardware I/O Register Allocation ($D000 - $D7FF)
    wire is_io_space = (ui_in[4:0] == 5'b11010);
    assert_io_decode: assert property (
        @(posedge clk) (rst_n && ena && is_io_space && uio_in[0]) |-> (uo_out[4] == 1'b0)
    );

    // =========================================================================
    // PRIORITY INTERLOCK AND EXCEPTION OVERRIDE DECODE PROOFS
    // =========================================================================

    // 4. Left Cartridge Priority Dominance Over BASIC Space
    assert_cartridge_dominance: assert property (
        @(posedge clk) (rst_n && ena && is_basic_space && !uio_in[3] && ui_in[7]) |-> (uo_out[1] == 1'b1)
    );

    // 5. Software OS Disabling via REN Control Loop
    assert_ren_disabled_os: assert property (
        @(posedge clk) (rst_n && ena && is_os_space && !uio_in[0]) |-> (uo_out[2] == 1'b1)
    );

    // 6. Refresh Wait-State CAS Inhibit Priority
    assert_refresh_cas_inhibit: assert property (
        @(posedge clk) (rst_n && ena && !uio_in[1]) |-> (uo_out[3] == 1'b0)
    );

    // 7. PBI Math Pack Address Conflict Disable ($D800)
    wire is_math_pack = (ui_in[4:0] == 5'b11011);
    assert_math_pack_disable: assert property (
        @(posedge clk) (rst_n && ena && is_math_pack && !uio_in[2]) |-> (uo_out[2] == 1'b1)
    );

    // =========================================================================
    // SYSTEM BOUNDARY ISOLATION SECURITY ASSERTIONS
    // =========================================================================

    // 8. Global System Master Cutoff Verification
    assert_safety_cutoff: assert property (
        @(posedge clk) (!rst_n || !ena) |-> (uo_out[5:0] == 6'b111111)
    );

    // 9. Unfiltered Pure Timing Probe Loopback Invariant
    assert_trigger_loopback: assert property (
        @(posedge clk) (uio_out == ui_in)
    );

endmodule

// =============================================================================
// SYSTEMVERILOG HIERARCHICAL BIND CONFIGURATION
// =============================================================================
// Inject the formal checker directly into the scope of your c061618g2 design.
bind c061618g2 tt_um_c061618g2_formal i_tt_um_c061618g2_formal (
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (uio_in),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (ena),
    .clk     (clk),
    .rst_n   (rst_n)
);
