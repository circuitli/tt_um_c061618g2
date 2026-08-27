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
    input  wire  [7:0] ui_in,    // Dedicated hardware inputs
    output logic [7:0] uo_out,   // Dedicated hardware outputs
    input  wire  [7:0] uio_in,   // Bidirectional bus input network
    output logic [7:0] uio_out,  // Bidirectional bus output network
    output logic [7:0] uio_oe,   // Safe output enablement bus mapping
    input  wire        ena,      // Tiny Tapeout macro environment block enable signal
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire        clk,      // Part of the strict wrapper standard!
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire        rst_n     // Part of the strict wrapper standard!
);
    /* verilator lint_off UNUSEDSIGNAL */
    bit unused_p2_b7 = uio_in[7]; // Breaks tracking graph at Time 0
    bit uio5_pad     = uio_in[5]; // Breaks tracking graph at Time 0
    bit TESTMODE_n   = uio_in[4]; // Breaks tracking graph at Time 0
    /* verilator lint_on UNUSEDSIGNAL */

    // =========================================================================
    // 3. HARDWARE BUS CONCATENATION (USING SAFE LAYER VALUES)
    // =========================================================================
    wire [12:0] functional_unfiltered;    
    assign functional_unfiltered = {
        uio_in[6],     // Bit 12 (MSB) -> FLG_IN_n
        uio_in[3:0],   // Bits 11:8    -> be_n, mpd_n, ref_n, ren
        ui_in[7:0]     // Bits 7:0     -> rd5, rd4, map_n, A15, A14, A13, A12, A11 (LSB)
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
    // 5. UNIDIRECTIONAL DECOUPLING LAYER (ICARUS COMPLIANT CONTINUOUS ASSIGNS)
    // Replaced the always_comb block to eliminate constant part-select crash bugs.
    // =========================================================================
    wire clean_ren;
    wire clean_ref_n;
    wire clean_mpd_n;
    wire clean_be_n;
    pmod1_inputs_t mmu_core_in;

    // Direct continuous wire decoupling assignments
    assign clean_ren   = filtered[8];  // ren (active-high)
    assign clean_ref_n = filtered[9];  // ref_n (active-low)
    assign clean_mpd_n = filtered[10]; // mpd_n (active-low)
    assign clean_be_n  = filtered[11]; // be_n  (active-low)
    
    assign mmu_core_in.control_bits = filtered[7:5]; // rd5, rd4, map_n
    assign mmu_core_in.addr         = filtered[4:0]; // A15, A14, A13, A12, A11

    pmod3_outputs_t core_signals;

    mmu_core core_inst (
        .rst_n    (rst_n),
        .core_in  (mmu_core_in), 
        .ren      (clean_ren),   
        .ref_n    (clean_ref_n), 
        .mpd_n    (clean_mpd_n), 
        .be_n     (clean_be_n),  
        .core_out (core_signals)
    );

    // =========================================================================
    // BUS TRISTATE SAFETY OVERRIDE
    // Completely forces all bidirectional pins to High-Z input mode during 
    // reset or macro disablement to prevent IO contention.
    // =========================================================================
    assign uio_oe = (rst_n && ena) ? 8'b00100000 : 8'b00000000; 

    // =========================================================================
    // CLEAN SILICON PROTECTION MATRIX (REAL HARDWARE LOGIC)
    // Stripped simulation-only '===' expressions to enable synthesis matching.
    // =========================================================================
    wire FLG_IN_n_top     = filtered[12];
    wire system_disabled  = (!FLG_IN_n_top) || (!ena) || (!rst_n);
    wire FLG_n            = system_disabled ? 1'b0 : 1'b1;
    wire a11_top          = filtered[0]; 

    /* verilator lint_off UNUSED */
    wire unused_p3_b7 = core_signals.unused_p3_b7;
    wire FLG_n_p3 = core_signals.FLG_n;
    /* verilator lint_on UNUSED */

    // =========================================================================
    // 6. PHYSICAL ROUTING MATRIX (PURE ASYNCHRONOUS PADS)
    // =========================================================================
    assign uio_out = system_disabled ? 8'b00000000 : {2'b00, a11_top, 5'b00000};

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