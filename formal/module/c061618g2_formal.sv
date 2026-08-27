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
`default_nettype none

module c061618g2_formal (
    input  wire        clk,           // Global verification clock
    input  wire        rst_n,         // Active-low system reset
    input  wire  [7:0] uo_out,        // Dedicated outputs bus
    input  wire  [7:0] uio_oe,        // Bidirectional output enablement bus
    input  wire        ena            // Environment block enable signal
);

`ifdef FORMAL

    // =========================================================================
    // 1. EXTRACT LIVE SELECTION NETS DIRECTLY FROM THE CORE INSTANCE
    // This allows us to track the true state of the MMU without duplicating logic equations.
    // =========================================================================
    wire s5_n    = c061618g2.core_signals.s5_n;
    wire basic_n = c061618g2.core_signals.basic_n;

    // =========================================================================
    // 2. TIMELINE PROOF CHECKING CORRIDOR
    // Evaluates strictly on the clock edge to break any zero-delay feedback paths.
    // =========================================================================
    always @(posedge clk) begin

        // --- PROOF A: GLOBAL RESET SAFE-STATE CONTRACTS ---
        // Verifies output pads instantly drop to their safe default values when reset is active.
        asm_top_reset_pad_7: assert (rst_n || (uo_out[7] == 1'b0));
        asm_top_reset_pad_6: assert (rst_n || (uo_out[6] == 1'b0)); // FLG_n clamp low
        asm_top_reset_pad_5: assert (rst_n || (uo_out[5] == 1'b1)); // S4 clamp high (inactive)
        asm_top_reset_pad_4: assert (rst_n || (uo_out[4] == 1'b1)); // IO clamp high (inactive)
        asm_top_reset_pad_3: assert (rst_n || (uo_out[3] == 1'b1)); // CI clamp high (inactive)
        asm_top_reset_pad_2: assert (rst_n || (uo_out[2] == 1'b1)); // OS clamp high (inactive)
        asm_top_reset_pad_1: assert (rst_n || (uo_out[1] == 1'b1)); // BASIC clamp high (inactive)
        asm_top_reset_pad_0: assert (rst_n || (uo_out[0] == 1'b1)); // S5 clamp high (inactive)

        // --- PROOF B: BUS HARDWARE SAFETY EXCLUSION ---
        // BASIC ROM and the Left Cartridge overlap on the system address bus.
        // They must NEVER activate at the same time to prevent short-circuits.
        asm_electrical_exclusion: assert (!rst_n || !ena || !(basic_n == 1'b0 && s5_n == 1'b0));

        // --- PROOF C: METASTABILITY & BUS CONTRAINT SAFETY ---
        asm_core_clean_uo_out: assert (!$isunknown(uo_out));
        asm_core_clean_uio_oe: assert (uio_oe == 8'b00100000 || uio_oe == 8'b00000000);

    end

`endif

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

