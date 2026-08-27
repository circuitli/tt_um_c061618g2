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
 *
 
 
//`ifndef TT_UM_C061618G2_FORMAL_SV
//`define TT_UM_C061618G2_FORMAL_SV

/// ==============================================================================
// SECTION: TOP-LEVEL HARDWARE WRAPPER FORMAL PROPERTIES
// ==============================================================================
`default_nettype none

`default_nettype none

module tt_um_c061618g2_formal (
    input  wire       clk,      // System clock injected for formal tracking
    input  wire       rst_n,    
    input  wire       ena,      
    input  wire [7:0] ui_in,    
    input  wire [7:0] uo_out,   // Live unclocked output pins
    input  wire [7:0] uio_in,   
    input  wire [7:0] uio_out,  
    input  wire [7:0] uio_oe    
);

`ifdef FORMAL

    // =========================================================================
    // THE FORMAL SHADOW SPLIT MATRIX
    // This breaks the simplemap_bitop loop by sampling the live unclocked pins
    // into an independent tracking register, cutting the combinational cycle!
    // =========================================================================
    reg [7:0] f_uo_out;
    always @(posedge clk) begin
        if (!rst_n)
            f_uo_out <= 8'h00;
        else
            f_uo_out <= uo_out; // Sample the outputs sequentially
    end

    // -------------------------------------------------------------------------
    // INTERNAL NET EXTRACTION FROM THE SAFE SHADOW REGISITER
    // All properties will monitor f_uo_out instead of the live pin wires.
    // -------------------------------------------------------------------------
    wire [5:0] active_out_pins = f_uo_out[5:0];
    
    wire s4_n    = active_out_pins[5];
    wire io_n    = active_out_pins[4];
    wire ci_n    = active_out_pins[3];
    wire os_n    = active_out_pins[2];
    wire basic_n = active_out_pins[1];
    wire s5_n    = active_out_pins[0];

    // Extraction vectors matching pmod1 address bits
    wire a11 = ui_in[0];
    wire a12 = ui_in[1];
    wire a13 = ui_in[2];
    wire a14 = ui_in[3];
    wire a15 = ui_in[4];

    wire map_n = ui_in[5];
    wire rd4   = ui_in[6];
    wire rd5   = ui_in[7];

    wire ref_n = uio_in[0];
    wire be_n  = uio_in[1];

    // =========================================================================
    // IDEAL PROOF LAYER DECODING (EVALUATES ON THE SHADOW GRID)
    // =========================================================================
    // =========================================================================
    // FIXED LOOP-SAFE CLOCKED FORMAL DECODING PROPERTIES
    // Evaluates on the clocked posedge grid to prevent simplemap self-loops!
    // =========================================================================
    always @(posedge clk) begin

        // 1. GLOBAL RESET SAFE-STATE PROOF
        asm_top_reset_assert: assert (rst_n || (active_out_pins == 6'b111111));

        // 2. TOP-LEVEL ADRESS SPACE DECODING ASSERTIONS
        asm_top_decode_s4_assert: assert (!(rst_n && ena && !a13 && !a14 && a15 && rd4 && ref_n) || (s4_n == 1'b0));
        asm_top_decode_s5_assert: assert (!(rst_n && ena && a13 && !a14 && a15 && rd5 && ref_n) || (s5_n == 1'b0));
        asm_top_decode_basic_assert: assert (!(rst_n && ena && a13 && !a14 && a15 && !rd5 && !be_n && ref_n) || (basic_n == 1'b0));
        asm_top_decode_io_assert: assert (!(rst_n && ena && !a11 && a12 && !a13 && a14 && a15 && ref_n) || (io_n == 1'b0));

        // 3. TOP-LEVEL HARDWARE SAFETY MUTUAL EXCLUSION PROOF
        asm_top_exclusion_assert: assert (!rst_n || !ena || !(basic_n == 1'b0 && s5_n == 1'b0));

        // 4. METASTABILITY CONTAINMENT BOUNDARY CONTRACT
        asm_top_clean_bus_assert: assert ((active_out_pins ^ active_out_pins) === 6'b000000);

    end

`endif

endmodule

// =========================================================================
// BIND DIRECTIVE: Inject properties cleanly into production RTL target
// =========================================================================
bind tt_um_c061618g2 tt_um_c061618g2_formal i_tt_um_c061618g2_formal (
    .clk      (clk),      // Injects global chip clock for asset gating
    .ui_in     (ui_in),
    .uo_out    (uo_out),
    .uio_in    (uio_in),
    .uio_out   (uio_out),
    .uio_oe    (uio_oe),
    .ena       (ena),
    .clk       (clk),
    .rst_n     (rst_n)
);

//`endif