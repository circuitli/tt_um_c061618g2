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

`default_nettype none

module c061618g2_formal (
    input  wire        clk,           // Global verification clock workaround
    input  wire        rst_n,         // Active-low system reset
    input  wire  [7:0] ui_in,         // FIXED: Added missing port vector slice
    input  wire  [7:0] uo_out,        // Dedicated outputs bus
    input  wire  [7:0] uio_in,        // FIXED: Added missing port vector slice
    input  wire  [7:0] uio_out,       // FIXED: Added missing port vector slice
    input  wire  [7:0] uio_oe,        // Bidirectional output enablement bus
    input  wire        ena            // Environment block enable signal
);

`ifdef FORMAL

    // =========================================================================
    // THE FORMAL SHADOW SPLIT MATRIX
    // Captures the unclocked main outputs sequentially to shatter the 
    // zero-delay feedback loops before simplemap_bitop$257 can form!
    // =========================================================================
    reg [7:0] f_uo_out;
    always @(posedge clk) begin
        if (!rst_n)
            f_uo_out <= 8'h00;
        else
            f_uo_out <= uo_out; // Sample the outputs sequentially
    end

    // -------------------------------------------------------------------------
    // INTERNAL NET EXTRACTION FROM THE SAFE SHADOW REGISTER
    // -------------------------------------------------------------------------
    wire [5:0] active_out_pins = f_uo_out[5:0];
    
    wire s5_n    = active_out_pins[0]; // Aligned to your physical bit index layout
    wire basic_n = active_out_pins[1]; // Bit 1 -> basic_n tracking target

    // =========================================================================
    // TIMELINE PROOF CHECKING CORRIDOR (EVALUATES ON THE SHADOW GRID)
    // =========================================================================
    always @(posedge clk) begin

        // --- PROOF A: GLOBAL RESET SAFE-STATE CONTRACTS ---
        asm_top_reset_pad_7: assert (rst_n || (f_uo_out[7] == 1'b0));
        asm_top_reset_pad_6: assert (rst_n || (f_uo_out[6] == 1'b0)); 
        asm_top_reset_pad_5: assert (rst_n || (active_out_pins[5] == 1'b1)); 
        asm_top_reset_pad_4: assert (rst_n || (active_out_pins[4] == 1'b1)); 
        asm_top_reset_pad_3: assert (rst_n || (active_out_pins[3] == 1'b1)); 
        asm_top_reset_pad_2: assert (rst_n || (active_out_pins[2] == 1'b1)); 
        asm_top_reset_pad_1: assert (rst_n || (basic_n == 1'b1)); 
        asm_top_reset_pad_0: assert (rst_n || (s5_n == 1'b1)); 

        // --- PROOF B: BUS HARDWARE SAFETY EXCLUSION ---
        asm_electrical_exclusion: assert (!rst_n || !ena || !(basic_n == 1'b0 && s5_n == 1'b0));

        // --- PROOF C: METASTABILITY & BUS CONSTRAINT SAFETY ---
        asm_core_clean_uo_out: assert (!$isunknown(f_uo_out));
        asm_core_clean_uio_oe: assert (uio_oe == 8'b00100000 || uio_oe == 8'b00000000);

    end

`endif

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
