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
    output [7:0] uo_out,   // Dedicated hardware outputs
    input  [7:0] uio_in,   // Bidirectional bus input network
    output [7:0] uio_out,  // Bidirectional bus output network
    output wire [7:0] uio_oe,   // Safe output enablement bus mapping
    input  ena,      // Tiny Tapeout macro environment block enable signal
    /* verilator lint_off UNUSEDSIGNAL */
    input  clk,      // Part of the strict wrapper standard!
    /* verilator lint_on UNUSEDSIGNAL */
    input  rst_n     // Part of the strict wrapper standard!
);

    // =========================================================================
    // 1. VERILATOR LINT FIX: LOCAL PORTS TO STRIP TRISTATE PROPERTY
    // Creating standard, non-tristate logic vectors forces Verilator to drop
    // the top-level 'inout' tracking graph before entering any logic lines.
    // =========================================================================
    logic [7:0] local_ui_in;
    logic [7:0] local_uio_in;
    
    assign local_ui_in  = ui_in;
    assign local_uio_in = uio_in;

    /* verilator lint_off UNUSEDSIGNAL */
    bit unused_p2_b7 = local_uio_in[7]; // Bit 7 -> Pmod 2, Pin 8 - Reserved
    bit uio5_pad     = local_uio_in[5]; // Bit 5 -> Pmod 2, Pin 6 (Exempted; Output Lane)
    bit TESTMODE_n   = local_uio_in[4]; // Industrial test platforms
    /* verilator lint_on UNUSEDSIGNAL */

    // =========================================================================
    // 2. INPUT CLEANSER LAYER (X/Z CASE-EQUALITY HARDWARE MASK)
    // Converts floating/uninitialized pins into safe, deterministic defaults.
    // =========================================================================
    logic [7:0] safe_ui, safe_uio;

     always_comb begin
        // --- ui_in Mapping (Address Bus and Control Signals) ---
        safe_ui[0] = (local_ui_in[0] === 1'bx || local_ui_in[0] === 1'bz) ? 1'b1 : (local_ui_in[0] == 1'b1); // A11
        safe_ui[1] = (local_ui_in[1] === 1'bx || local_ui_in[1] === 1'bz) ? 1'b1 : (local_ui_in[1] == 1'b1); // A12
        safe_ui[2] = (local_ui_in[2] === 1'bx || local_ui_in[2] === 1'bz) ? 1'b1 : (local_ui_in[2] == 1'b1); // A13
        safe_ui[3] = (local_ui_in[3] === 1'bx || local_ui_in[3] === 1'bz) ? 1'b1 : (local_ui_in[3] == 1'b1); // A14
        safe_ui[4] = (local_ui_in[4] === 1'bx || local_ui_in[4] === 1'bz) ? 1'b1 : (local_ui_in[4] == 1'b1); // A15
        safe_ui[5] = (local_ui_in[5] === 1'bx || local_ui_in[5] === 1'bz) ? 1'b1 : (local_ui_in[5] == 1'b1); // map_n
        safe_ui[6] = (local_ui_in[6] === 1'bx || local_ui_in[6] === 1'bz) ? 1'b0 : (local_ui_in[6] == 1'b1); // rd4
        safe_ui[7] = (local_ui_in[7] === 1'bx || local_ui_in[7] === 1'bz) ? 1'b0 : (local_ui_in[7] == 1'b1); // rd5

        // --- uio_in Mapping (Pmod 2 Control Channels) ---
        // FIXED FOR POLARITY: ren is active-high, so its fallback must default to 1'b0!
        safe_uio[0] = (local_uio_in[0] === 1'bx || local_uio_in[0] === 1'bz) ? 1'b0 : (local_uio_in[0] == 1'b1); // ren -> 0
        
        // Active-low control channels default high (1'b1)
        safe_uio[1] = (local_uio_in[1] === 1'bx || local_uio_in[1] === 1'bz) ? 1'b1 : (local_uio_in[1] == 1'b1); // ref_n 
        safe_uio[2] = (local_uio_in[2] === 1'bx || local_uio_in[2] === 1'bz) ? 1'b1 : (local_uio_in[2] == 1'b1); // mpd_n 
        safe_uio[3] = (local_uio_in[3] === 1'bx || local_uio_in[3] === 1'bz) ? 1'b1 : (local_uio_in[3] == 1'b1); // be_n  
        safe_uio[6] = (local_uio_in[6] === 1'bx || local_uio_in[6] === 1'bz) ? 1'b1 : (local_uio_in[6] == 1'b1); // FLG_IN_n

        // Route remaining unreferenced bits to prevent UNUSEDSIGNAL warnings cleanly
        safe_uio[4] = local_uio_in[4];
        safe_uio[5] = local_uio_in[5];
        safe_uio[7] = local_uio_in[7];
    end

    // =========================================================================
    // 3. HARDWARE BUS CONCATENATION (USING SAFE LAYER VALUES)
    // =========================================================================
    wire [12:0] functional_unfiltered;    
    assign functional_unfiltered = {
        safe_uio[6],     // Bit 12 (MSB) -> FLG_IN_n
        safe_uio[3:0],   // Bits 11:8    -> be_n, mpd_n, ref_n, ren
        safe_ui[7:0]     // Bits 7:0     -> rd5, rd4, map_n, A15, A14, A13, A12, A11 (LSB)
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
        // Straight, non-inverting 1-to-1 data pass-through to satisfy the Verilator compiler
        clean_ren   = filtered[8];  // ren   (active-high)
        clean_ref_n = filtered[9];  // ref_n (active-low)
        clean_mpd_n = filtered[10]; // mpd_n (active-low)
        clean_be_n  = filtered[11]; // be_n  (active-low)
        
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