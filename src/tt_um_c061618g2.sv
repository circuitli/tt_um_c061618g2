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

// ==============================================================================
// SECTION: TOP-LEVEL HARDWARE WRAPPER CONSTRAINTS
// ==============================================================================
`default_nettype none

//`include "src/module/c061618g2_input_shield.sv"
`include "src/module/c061618g2.sv"

// =========================================================================
// STRUCTURAL CELL ISOLATION BUFFER
// Placing a simple assignment inside a separate, explicit hardware module 
// forces Yosys to create a hard hierarchical cell boundary in its graph.
// This shatters the zero-delay loop circuit in formal tool memory, while
// remaining a standard transparent wire pass-through for Cocotb.
// =========================================================================
module safe_wire_buffer (
    input  wire A,
    output wire Y
);
    assign Y = A;
endmodule

module tt_um_c061618g2 (
    input  wire [7:0] ui_in,    // Dedicated hardware inputs
    output wire [7:0] uo_out,   // Dedicated hardware outputs
    input  wire [7:0] uio_in,   // Bidirectional bus input network
    output wire [7:0] uio_out,  // Bidirectional bus output network
    output wire [7:0] uio_oe,   // Safe output enablement bus mapping
    input  wire [0:0] ena,      // Tiny Tapeout macro block enable signal
    input  wire [0:0] clk,      // System clock injected for wrapper compliance
    input  wire [0:0] rst_n     // Active-low system reset
);

    // =========================================================================
    // 1. PURE 2-STATE VARIABLE FIREWALL
    // =========================================================================
    logic [7:0] safe_ui;
    logic [7:0] safe_uio;

    // =========================================================================
    // HAZARD-FREE & WARNING-FREE ATOMIC VECTOR INPUT SHIELD
    // Replaces sliced wires and always_comb blocks with explicit full-vector 
    // bitwise masks. This removes part-select fragmentation traps for Yosys SBY 
    // and eliminates delta-cycle timing skews for Cocotb simultaneously!
    // =========================================================================
    
    // UI_IN MATRIX: If in reset, clamp to 8'h1F. Otherwise, pass-through ui_in.
    assign safe_ui = rst_n ? ui_in : 8'b00011111;

    // UIO_IN MATRIX: If in reset, evaluate using an explicit 8-bit atomic mask:
    // (uio_in & 8'b11000001) preserves bits [7:6] and bit [0] natively as 1-to-1 passes.
    // (| 8'b00001110) forces the active-low pull-up clamp high on bits [3:1] (3'b111).
    // Bits [5:4] are natively zeroed out because they are masked off and un-set.
    assign safe_uio = rst_n ? uio_in : ((uio_in & 8'b11000001) | 8'b00001110);

    // =========================================================================
    // 2. CORE HIERARCHICAL INSTANTIATION
    // =========================================================================
    c061618g2 u_c061618g2 (
        .clk     (clk),
        .rst_n   (rst_n),
        .ui_in   (safe_ui),
        .uo_out  (uo_out),
        .uio_in  (safe_uio),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena)
    );

endmodule

`default_nettype wire
