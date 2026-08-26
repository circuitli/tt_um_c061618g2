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

`ifndef C061618G2_SV
`define C061618G2_SV
`default_nettype none

// ==============================================================================
// MMU MODULE
// ==============================================================================
`include "src/core/mmu_core.sv"
`include "src/module/async_glitch_filter_bank.sv"

(* keep_hierarchy = 1 *)
// =========================================================================
// CUSTOM MMU - TINY TAPEOUT COMPLIANT
// =========================================================================
module c061618g2 (
    input  [7:0] ui_in,    // Dedicated hardware inputs
    output wire [7:0] uo_out,   // Dedicated hardware outputs
    input  [7:0] uio_in,   // Bidirectional bus input network
    output wire [7:0] uio_out,  // Bidirectional bus output network
    output wire [7:0] uio_oe,   // Safe output enablement bus mapping
    input  ena,      // Tiny Tapeout macro environment block enable signal
    /* verilator lint_off UNUSEDSIGNAL */
    input  clk,      // Part of the strict wrapper standard!
    /* verilator lint_on UNUSEDSIGNAL */
    input  rst_n     // Part of the strict wrapper standard!
);
    /* verilator lint_off UNUSEDSIGNAL */
    bit unused_p2_b7 = uio_in[7] & 1'b1; // Breaks tracking graph at Time 0
    bit uio5_pad     = uio_in[5] & 1'b1; // Breaks tracking graph at Time 0
    bit TESTMODE_n   = uio_in[4] & 1'b1; // Breaks tracking graph at Time 0
    /* verilator lint_on UNUSEDSIGNAL */

    // =========================================================================
    // 1. SCALAR TRISTATE SHATTER LAYER (PRESERVES TRUE STARTUP POLARITIES)
    // Declaring explicit, separate 1-bit wires forces Verilator to drop the 
    // bidirectional vector dependency graph right at the chip's edge.
    // =========================================================================
    
    // --- Unpacked ui_in Scalar Wires ---
    wire s_ui0 = (ui_in[0] === 1'bx || ui_in[0] === 1'bz) ? 1'b1 : (ui_in[0] == 1'b1); // A11
    wire s_ui1 = (ui_in[1] === 1'bx || ui_in[1] === 1'bz) ? 1'b1 : (ui_in[1] == 1'b1); // A12
    wire s_ui2 = (ui_in[2] === 1'bx || ui_in[2] === 1'bz) ? 1'b1 : (ui_in[2] == 1'b1); // A13
    wire s_ui3 = (ui_in[3] === 1'bx || ui_in[3] === 1'bz) ? 1'b1 : (ui_in[3] == 1'b1); // A14
    wire s_ui4 = (ui_in[4] === 1'bx || ui_in[4] === 1'bz) ? 1'b1 : (ui_in[4] == 1'b1); // A15
    wire s_ui5 = (ui_in[5] === 1'bx || ui_in[5] === 1'bz) ? 1'b1 : (ui_in[5] == 1'b1); // map_n
    wire s_ui6 = (ui_in[6] === 1'bx || ui_in[6] === 1'bz) ? 1'b0 : (ui_in[6] == 1'b1); // rd4 -> 0
    wire s_ui7 = (ui_in[7] === 1'bx || ui_in[7] === 1'bz) ? 1'b0 : (ui_in[7] == 1'b1); // rd5 -> 0

    // --- Unpacked uio_in Scalar Wires ---
    wire s_uio0 = (uio_in[0] === 1'bx || uio_in[0] === 1'bz) ? 1'b0 : (uio_in[0] == 1'b1); // ren -> 0
    wire s_uio1 = (uio_in[1] === 1'bx || uio_in[1] === 1'bz) ? 1'b1 : (uio_in[1] == 1'b1); // ref_n 
    wire s_uio2 = (uio_in[2] === 1'bx || uio_in[2] === 1'bz) ? 1'b1 : (uio_in[2] == 1'b1); // mpd_n 
    wire s_uio3 = (uio_in[3] === 1'bx || uio_in[3] === 1'bz) ? 1'b1 : (uio_in[3] == 1'b1); // be_n  
    wire s_uio6 = (uio_in[6] === 1'bx || uio_in[6] === 1'bz) ? 1'b1 : (uio_in[6] == 1'b1); // FLG_IN_n

    // --- Unpacked Padding Scalar Wires ---
    wire s_uio4 = (uio_in[4] == 1'b1);
    wire s_uio5 = (uio_in[5] == 1'b1);
    wire s_uio7 = (uio_in[7] == 1'b1);

    // =========================================================================
    // 2. SAFE MULTI-BIT VECTOR RECONSTRUCTION
    // The rebuilt arrays are now verified 2-state nets, completely immune to 
    // tristate propagation errors when passed across module boundaries.
    // =========================================================================
    wire [7:0] clean_ui  = {s_ui7,  s_ui6,  s_ui5,  s_ui4,  s_ui3,  s_ui2,  s_ui1,  s_ui0};
    wire [7:0] clean_uio = {s_uio7, s_uio6, s_uio5, s_uio4, s_uio3, s_uio2, s_uio1, s_uio0};

    // =========================================================================
    // 3. HARDWARE BUS CONCATENATION (USING SAFE LAYER VALUES)
    // =========================================================================
    wire [12:0] functional_unfiltered;    
    assign functional_unfiltered = {
        clean_uio[6],     // Bit 12 (MSB) -> FLG_IN_n
        clean_uio[3:0],   // Bits 11:8    -> be_n, mpd_n, ref_n, ren
        clean_ui[7:0]     // Bits 7:0     -> rd5, rd4, map_n, A15, A14, A13, A12, A11 (LSB)
    };

    // =========================================================================
    // 4. CLOCKLESS ASYNCHRONOUS GLITCH FILTER MATRIX
    // =========================================================================
    wire [12:0] filtered;
    
    async_glitch_filter_bank #(
        .WIDTH(13),
        .STAGES(4)
    ) u_mmu_filter_bank (
        .rst_n    (rst_n), 
        .async_in (functional_unfiltered),
        .async_out(filtered)
    );

    // =========================================================================
    // 5. UNIDIRECTIONAL DECOUPLING LAYER (EXPLICIT DATA PASS-THROUGH)
    // =========================================================================
    logic clean_ren;
    logic clean_ref_n;
    logic clean_mpd_n;
    logic clean_be_n;
    pmod1_inputs_t mmu_core_in;

    always_comb begin
        // CORRECTED CHECK: Evaluates to 1'b0 (disabled) when the filtered pin is 0,
        // matching the active-high polarity of the ren line exactly.
        clean_ren   = (filtered[8]  == 1'b1) ? 1'b1 : 1'b0; // ren (active-high)
        
        // Active-low lines pass their true values straight through
        clean_ref_n = (filtered[9]  == 1'b1); // ref_n (active-low)
        clean_mpd_n = (filtered[10] == 1'b1); // mpd_n (active-low)
        clean_be_n  = (filtered[11] == 1'b1); // be_n  (active-low)
        
        mmu_core_in.control_bits = filtered[7:5]; // rd5, rd4, map_n
        mmu_core_in.addr         = filtered[4:0]; // A15, A14, A13, A12, A11
    end

    pmod3_outputs_t core_signals;

    mmu_core core_inst (
        .core_in  (mmu_core_in), 
        .ren      (clean_ren),   
        .ref_n    (clean_ref_n), 
        .mpd_n    (clean_mpd_n), 
        .be_n     (clean_be_n),  
        .core_out (core_signals)
    );

    // ---- BUS DIRECTION HARDCODING ----
    assign uio_oe = 8'b00100000; 

    wire FLG_IN_n_top = filtered[12];
    wire system_disabled = (FLG_IN_n_top === 1'b0) || (ena === 1'b0) || (rst_n === 1'b0);
    wire FLG_n = system_disabled ? 1'b0 : 1'b1;
    wire a11_top = filtered[0]; 

    /* verilator lint_off UNUSED */
    wire unused_p3_b7 = core_signals.unused_p3_b7;
    wire FLG_n_p3 = core_signals.FLG_n;
    /* verilator lint_on UNUSED */

    // =========================================================================
    // 6. PHYSICAL ROUTING MATRIX (PURE ASYNCHRONOUS PADS)
    // =========================================================================
    assign uio_out = {2'b00, a11_top, 5'b00000};

    assign uo_out[7] = 1'b0;                                                // Static ground tie-off
    assign uo_out[6] = FLG_n;                                               // Instant, filtered safety status 
    assign uo_out[5] = system_disabled ? 1'b1 : core_signals.s4_n;          // S4 Expansion Select Lane
    assign uo_out[4] = system_disabled ? 1'b1 : core_signals.io_n;          // Hardware I/O Select Lane
    assign uo_out[3] = system_disabled ? 1'b1 : core_signals.ci_n;          // CAS Inhibit Lane
    assign uo_out[2] = system_disabled ? 1'b1 : core_signals.os_n;          // OS Kernel Selected Memory Lane
    assign uo_out[1] = system_disabled ? 1'b1 : core_signals.basic_n;       // BASIC Interpreter Selected Memory Lane
    assign uo_out[0] = system_disabled ? 1'b1 : core_signals.s5_n;          // S5 Expansion Select Lane

endmodule

`default_nettype wire
`endif