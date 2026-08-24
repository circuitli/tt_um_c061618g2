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
`include "src/defs/mmu_defs.sv"
`include "src/core/mmu_core.sv"
`include "src/module/async_glitch_filter_bank.sv"

(* keep_hierarchy = 1 *)
module c061618g2 (
    input  [7:0] ui_in,    // Dedicated hardware inputs
    output [7:0] uo_out,   // Dedicated hardware outputs
    input  [7:0] uio_in,   // Bidirectional bus input network
    output [7:0] uio_out,  // Bidirectional bus output network
    output wire [7:0] uio_oe,   // <-- MUST BE DECLARED AS AN OUTPUT PORT WIRE HERE! [2]
    input  ena,      // Leave this here! The compiler requires it.
    input  clk,      // Part of the strict wrapper standard!
    input  rst_n     // Part of the strict wrapper standard!
);

    wire TESTMODE_n = uio_in[4]; // Industrial test platforms

    // 2. Continuous 13-bit concatenation (MSB to LSB)
    //    ui_in[0] (A11) naturally lands at index 0 (LSB) of the bus!
    // =========================================================================
    // THE DEFINITIVE WIRE TYPE CONVERSION (NO IFDEF)
    // By changing functional_unfiltered from 'logic' to 'wire', Icarus Verilog 
    // preserves the structural timing boundaries across the bidirectional pad traces.
    // =========================================================================
    wire [12:0] functional_unfiltered;    assign functional_unfiltered = {
        uio_in[6],    // Bit 12 (MSB) -> FLG_IN_n
        uio_in[3:0],  // Bits 11:8    -> be_n, mpd_n, ref_n, ren
        ui_in[7:0]    // Bits 7:0     -> rd5, rd4, map_n, A15, A14, A13, A12, A11 (LSB)
    };

    // 3. Instantiate the 13-channel variable-width filter bank
    // =========================================================================
    // CONVERT LOGIC TO WIRE TYPE BUSES
    // By explicitly declaring these tracking nets as 'wire' instead of 'logic',
    // we force Icarus Verilog to respect the structural #1 delay parameter.
    // This breaks the zero-delay loop graph and unblocks the 120.00 ns freeze.
    // =========================================================================
    
    // 1. Change filtered_raw to a wire type bus
    (* loop_break *) wire [12:0] filtered_raw;
    
    async_glitch_filter_bank #(
        .WIDTH(13),
        .STAGES(4)
    ) u_mmu_filter_bank (
        .rst_n(rst_n), 
        .async_in  (functional_unfiltered),
        .async_out (filtered_raw)
    );

    // 2. Change filtered to a wire type bus
    wire [12:0] filtered;
    
    `ifdef COCOTB_SIM
        assign #1 filtered = filtered_raw;
    `else
        assign filtered = filtered_raw;
    `endif

    // Slicing bits 11 down to 8 from the 'filtered' bus maps exactly 
    // to the order they were packed into the concatenation vector above.
    logic clean_be_n;
    logic clean_mpd_n;
    logic clean_ref_n;
    logic clean_ren;

    assign {clean_be_n, clean_mpd_n, clean_ref_n, clean_ren} = filtered[11:8];

    // =========================================================================
    // SEPARATED INTERFACE STRUCTURE BINDING
    // =========================================================================
     /* verilator lint_off UNUSED */
    pmod2_outputs_t pmod2_out_bus;
    /* verilator lint_on UNUSED */
    
    // ---- BUS DIRECTION HARDCODING ----
    assign uio_oe = 8'b00100000; 

    /* verilator lint_off UNUSED */
    //wire unused_p2_b7 = uio_in[7]; // Bit 7 -> Pmod 2, Pin 8
    //wire uio5_pad     = uio_in[5];  // Bit 5 -> Pmod 2, Pin 6 (Exempted; Output Lane)
    /* verilator lint_on UNUSED */

    // =========================================================================
    // CORE SELECTIONS & DECODING PASS
    // =========================================================================
    pmod3_outputs_t core_signals;

    // 1. Process Core Decoding Matrix
    mmu_core core_inst (
        .core_in  (filtered[7:0]),     // Direct flat 8-bit bus copy
        .ren      (clean_ren), // Bypass structure parsing via direct raw bit indexing
        .ref_n    (clean_ref_n),
        .mpd_n    (clean_mpd_n),
        .be_n     (clean_be_n), 
        .core_out (core_signals)
    );

    wire FLG_IN_n = filtered[12];

    // Evaluate master system override control flags
    // If any of them drop to 0, functional operations are disabled.
    wire system_disabled = (FLG_IN_n == 1'b0) || (ena == 1'b0) || (rst_n == 1'b0);
    wire FLG_n = !system_disabled;

    // Move the selection outside into a continuous assignment
    wire a11 = filtered[0]; 

    /* verilator lint_off UNUSED */
    wire unused_p3_b7 = core_signals.unused_p3_b7;
    wire FLG_n_p3 = core_signals.FLG_n;
    /* verilator lint_on UNUSED */

        // =========================================================================
    // PHYSICAL ROUTING MATRIX (Instantaneous Pure Combinational Outputs)
    // =========================================================================
    
    // --- Pmod 2 Outputs Mapping ---
    // TRIGGER_OUT maps explicitly to Bit 5.
    assign uio_out = {2'b00, a11, 5'b00000};

    // --- Pmod 3 Outputs Mapping (uo_out) ---
    // All output registers are removed. Core decoded signals flow instantly to the pads.
    // When system_disabled is active, all active-low chips selects are forced high (deasserted).
    
    assign uo_out[7] = 1'b0;                                                // Static ground tie-off
    assign uo_out[6] = FLG_n;                                               // Instant, filtered safety status 
    assign uo_out[5] = system_disabled ? 1'b1 : core_signals.s4_n;          // S4 Expansion Select Lane
    assign uo_out[4] = system_disabled ? 1'b1 : core_signals.io_n;          // Hardware I/O Select Lane
    assign uo_out[3] = system_disabled ? 1'b1 : core_signals.ci_n;          // CAS Inhibit Lane
    assign uo_out[2] = system_disabled ? 1'b1 : core_signals.os_n;          // OS Kernel Selected Memory Lane
    assign uo_out[1] = system_disabled ? 1'b1 : core_signals.basic_n;       // BASIC Interpreter Selected Memory Lane
    assign uo_out[0] = system_disabled ? 1'b1 : core_signals.s5_n;          // S5 Expansion Select Lane

endmodule

`endif