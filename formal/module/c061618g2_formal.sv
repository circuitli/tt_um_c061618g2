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

// =============================================================================
// Top-Level Formal Verification Container: tt_um_c061618g2_formal
// Fully clockless to match our purely asynchronous IHP silicon layout.
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

    // Casting wires to our structured layout types to make the properties readable
    // and completely safe against pin-ordering bugs.
    wire pmod1_inputs_t  p1_in  = pmod1_inputs_t'(ui_in);
    wire pmod2_inputs_t  p2_in  = pmod2_inputs_t?(uio_in);
    wire pmod2_outputs_t p2_out = pmod2_outputs_t'(uio_out);
    wire pmod3_outputs_t p3_out = pmod3_outputs_t'(uo_out);

    // =========================================================================
    // ARCHITECTURAL ENVIRONMENTAL ASSUMPTIONS (Combinatorial Invariants)
    // =========================================================================
    
    // TinyTapeout rule: Ensure the design is always selected during validation
    assume_system_enabled: assume property (ena == 1'b1);

    // =========================================================================
    // EXHAUSTIVE MEMORY DECODER MAPPING ASSERTIONS (Clockless Boolean)
    // =========================================================================
    
    // 1. Operating System ROM Allocation ($F800 - $FFFF)
    // Upper address bits match 5'b11111
    wire is_os_space = (p1_in.addr == 5'b11111); 
    assert_os_decode: assert property (
        !(rst_n && is_os_space && p2_in.ren && p2_in.ref_n) || (p3_out.os_n == 1'b0)
    );

    // 2. BASIC Interpreter Memory Map Allocation ($A000 - $BFFF)
    // Address bits match 2'b10xx
    wire is_basic_space = (p1_in.addr[4:3] == 2'b10); 
    assert_basic_decode: assert property (
        !(rst_n && is_basic_space && !p2_in.be_n && p2_in.ref_n && !p1_in.control_bits[2]) || (p3_out.basic_n == 1'b0)
    );

    // 3. Peripheral Hardware I/O Register Allocation ($D000 - $D7FF)
    wire is_io_space = (p1_in.addr == 5'b11010);
    assert_io_decode: assert property (
        !(rst_n && is_io_space && p2_in.ref_n) || (p3_out.io_n == 1'b0)
    );

    // =========================================================================
    // PRIORITY INTERLOCK AND EXCEPTION OVERRIDE DECODE PROOFS
    // =========================================================================

    // 4. Left Cartridge Priority Dominance Over BASIC Space
    // control_bits[2] represents rd5 (Left Cartridge Sense)
    assert_cartridge_dominance: assert property (
        !(rst_n && is_basic_space && !p2_in.be_n && p1_in.control_bits[2]) || (p3_out.basic_n == 1'b1)
    );

    // 5. Software OS Disabling via REN Control Loop
    assert_ren_disabled_os: assert property (
        !(rst_n && is_os_space && !p2_in.ren) || (p3_out.os_n == 1'b1)
    );

    // 6. Refresh Wait-State CAS Inhibit Priority
    assert_refresh_cas_inhibit: assert property (
        !(rst_n && !p2_in.ref_n) || (p3_out.ci_n == 1'b0)
    );

    // 7. PBI Math Pack Address Conflict Disable ($D800)
    wire is_math_pack = (p1_in.addr == 5'b11011);
    assert_math_pack_disable: assert property (
        !(rst_n && is_math_pack && !p2_in.mpd_n) || (p3_out.os_n == 1'b1)
    );

    // =========================================================================
    // SYSTEM BOUNDARY ISOLATION SECURITY ASSERTIONS
    // =========================================================================

    // 8. Global System Master Cutoff Verification (Reset Override)
    assert_safety_cutoff: assert property (
        (rst_n) || (uo_out[5:0] == 6'b111111)
    );

    // 9. Unfiltered Pure Timing Probe Loopback Invariant
    assert_trigger_loopback: assert property (
        !(rst_n) || (p2_out.TRIGGER_OUT == p1_in.control_bits[0]) // Maps map_n directly out
    );

endmodule

// =============================================================================
// CORRECTED SYSTEMVERILOG HIERARCHICAL BIND CONFIGURATION
// Binds precisely to the correct TinyTapeout top-level module block name.
// =============================================================================
bind tt_um_c061618g2 tt_um_c061618g2_formal i_tt_um_c061618g2_formal (
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (uio_in),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (ena),
    .clk     (clk),
    .rst_n   (rst_n)
);

`default_nettype wire
`endif // C061618G2_FORMAL_SV

