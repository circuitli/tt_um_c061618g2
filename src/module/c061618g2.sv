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
`include "src/module/clock_synchronizer.sv"
`include "src/module/anti_glitch_filter.sv"

(* keep_hierarchy = "yes" *)
module c061618g2 (
    input  [7:0] ui_in,    // Dedicated hardware inputs
    output [7:0] uo_out,   // Dedicated hardware outputs
    input  [7:0] uio_in,   // Bidirectional bus input network
    output [7:0] uio_out,  // Bidirectional bus output network
    output wire [7:0] uio_oe,   // <-- MUST BE DECLARED AS AN OUTPUT PORT WIRE HERE! [2]
    input  [0:0] ena,      // Leave this here! The compiler requires it.
    input  [0:0] clk,      // Part of the strict wrapper standard!
    input  [0:0] rst_n     // Part of the strict wrapper standard!
);

    wire TESTMODE_n = uio_in[4]; // Industrial test platforms
    wire FLG_IN_n      = uio_in[6]; // Consolidated active-low safety fault line

    // Force both Yosys and OpenROAD to preserve this exact net name 
    // and prevent it from being renamed or optimized during flattening.
    (* keep = "true", dont_touch = "true" *) wire sys_clk;

    // 2. Instantiate Clock Synchronizer
    // Converts incoming active-low rst_n to active-high reset layout
    clock_synchronizer #(
        .STAGES(2)
    ) u_clock_sync (
        .rst      (!rst_n),
        .raw_clk  (clk),
        .sync_clk (sys_clk)
    );

    // DFT Bypass Clock Tree Selector
    wire phase_clk = !TESTMODE_n ? clk : sys_clk;

    // =========================================================================
    // SEPARATED INTERFACE STRUCTURE BINDING
    // =========================================================================
     /* verilator lint_off UNUSED */
    pmod1_inputs_t  pmod1_bus;
    pmod2_inputs_t  pmod2_in_bus;
    pmod2_outputs_t pmod2_out_bus;
    /* verilator lint_on UNUSED */

    // Map input vectors cleanly index-for-index
    assign pmod1_bus    = ui_in;
    assign pmod2_in_bus = uio_in;
    
    // ---- BUS DIRECTION HARDCODING ----
    assign uio_oe = 8'b00100000; 

    /* verilator lint_off UNUSED */
    //wire unused_p2_b7 = pmod2_in_bus[7]; // Bit 7 -> Pmod 2, Pin 8
    //wire uio5_pad     = pmod2_in_bus[5];  // Bit 5 -> Pmod 2, Pin 6 (Exempted; Output Lane)
    /* verilator lint_on UNUSED */

    // =========================================================================
    // CORE SELECTIONS & DECODING PASS
    // =========================================================================
    pmod3_outputs_t core_signals;
    bit         stabilized_ci_n;

    // 1. Process Core Decoding Matrix
    mmu_core core_inst (
        .core_in  (ui_in),     // Direct flat 8-bit bus copy
        .ren      (uio_in[0]), // Bypass structure parsing via direct raw bit indexing
        .ref_n    (uio_in[1]),
        .mpd_n    (uio_in[2]),
        .be_n     (uio_in[3]), 
        .core_out (core_signals)
    );

    // 2. Clear RAM toggles via the delay filter circuit
    anti_glitch_filter filter_inst (
        .clk              (phase_clk),     // Connect the system clock line
        .rst_n            (rst_n),         // Connect the global reset line
        .TESTMODE_n       (TESTMODE_n),    // Connect the full production test port
        .raw_signal_in    (core_signals.ci_n),
        .clean_signal_out (stabilized_ci_n)
    );

    // Evaluate master system override control flags
    // If any of them drop to 0, functional operations are disabled.
    wire system_disabled = (FLG_IN_n == 1'b0) || (ena == 1'b0) || (rst_n == 1'b0);

    // Move the selection outside into a continuous assignment
    wire a11 = pmod1_bus.addr[0]; 

    /* verilator lint_off UNUSED */
    wire unused_p3_b7 = core_signals.unused_p3_b7;
    wire LOOP_OUT     = core_signals.LOOP_OUT;
    /* verilator lint_on UNUSED */

    // =========================================================================
    // PHYSICAL ROUTING MATRIX (Continuous Assigns Only)
    // =========================================================================
    
    // --- Pmod 2 Outputs Mapping ---
    // Replaced the structure assignment pattern '{...} syntax to avoid Icarus Verilog parser errors.
    // TRIGGER_OUT maps explicitly to Bit 5 of your 8-bit packed bidirectional output bus.
    assign uio_out = {2'b00, a11, 5'b00000};

    // --- Pmod 3 Outputs Mapping (uo_out) ---
    assign uo_out[7] = 1'b0; // Static ground tie-off
    assign uo_out[6] = system_disabled ? 1'b1 : core_signals.LOOP_OUT;
    assign uo_out[5] = system_disabled ? 1'b1 : core_signals.s4_n;
    assign uo_out[4] = system_disabled ? 1'b1 : core_signals.io_n;
    assign uo_out[3] = system_disabled ? 1'b1 : stabilized_ci_n;
    assign uo_out[2] = system_disabled ? 1'b1 : core_signals.os_n;
    assign uo_out[1] = system_disabled ? 1'b1 : core_signals.basic_n;
    assign uo_out[0] = system_disabled ? 1'b1 : core_signals.s5_n;

endmodule

`endif