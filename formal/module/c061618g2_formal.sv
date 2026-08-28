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

module c061618g2_formal (
    input  wire        clk,           // Unused verification clock hook
    input  wire        rst_n,         // Active-low system reset
    input  wire  [7:0] ui_in,         
    input  wire  [7:0] uo_out,        // Live, unclocked physical outputs bus
    input  wire  [7:0] uio_in,         
    input  wire  [7:0] uio_out,        
    input  wire  [7:0] uio_oe,        // Bidirectional output enablement bus
    input  wire        ena            // Environment block enable signal
);

    // -------------------------------------------------------------------------
    // DIRECT LIVE NET EXTRACTION 
    // Extracts bits continuously from the real physical outputs
    // -------------------------------------------------------------------------
    wire [5:0] active_out_pins = uo_out[5:0];
    
    wire s5_n    = active_out_pins[0]; // Aligned to your physical bit index layout
    wire basic_n = active_out_pins[1]; // Bit 1 -> basic_n tracking target

    // =========================================================================
    // GCLK-FREE COMBINATIONAL VERIFICATION CORRIDOR
    // Evaluates constraints instantly on any live physical pin state updates.
    // =========================================================================
    always @* begin

        // --- PROOF A: GLOBAL RESET SAFE-STATE CONTRACTS ---
        // Verifies the exact physical bit vector mapping matching 8'b00111111 ($3F)
        asm_top_reset_pad_7: assert (rst_n || (uo_out[7] == 1'b0)); // Static Ground Tie-off
        asm_top_reset_pad_6: assert (rst_n || (uo_out[6] == 1'b0)); // FLG_n asserts low when system is disabled
        asm_top_reset_pad_5: assert (rst_n || (active_out_pins[5] == 1'b1)); // s4_n high
        asm_top_reset_pad_4: assert (rst_n || (active_out_pins[4] == 1'b1)); // io_n high
        asm_top_reset_pad_3: assert (rst_n || (active_out_pins[3] == 1'b1)); // ci_n high
        asm_top_reset_pad_2: assert (rst_n || (active_out_pins[2] == 1'b1)); // os_n high
        asm_top_reset_pad_1: assert (rst_n || (basic_n == 1'b1));            // basic_n high
        asm_top_reset_pad_0: assert (rst_n || (s5_n == 1'b1));               // s5_n high

        // --- PROOF B: BUS HARDWARE SAFETY EXCLUSION ---
        // Guarantees that BASIC and OS memory channels can never assert simultaneously
        asm_electrical_exclusion: assert (!rst_n || !ena || !(basic_n == 1'b0 && s5_n == 1'b0));

        // --- PROOF C: METASTABILITY & BUS CONSTRAINT SAFETY ---
        // Verifies bidirectional port enablement operates inside strict safe frames
        asm_core_clean_uio_oe: assert (uio_oe == 8'b00100000 || uio_oe == 8'b00000000);

    end

endmodule

`default_nettype wire
Use code with caution.Now that the formal module perfectly mirrors the corrected hardware state, run SymbiYosys once more to verify everything compiles cleanly.Let me know if both Cocotb and SBY are completely green and PASSED!

endmodule

// =============================================================================
// SYSTEMVERILOG HIERARCHICAL BIND CONFIGURATION
// =============================================================================
bind c061618g2 c061618g2_formal i_c061618g2_formal (
    .clk     (clk),
    .rst_n   (rst_n),
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (uio_in),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (ena)
);

`default_nettype wire
`endif // C061618G2_FORMAL_SV
