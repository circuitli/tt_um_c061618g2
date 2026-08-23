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
`include "src/module/signal_divider_by_4.sv"

(* keep_hierarchy = 1 *)
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
    wire FLG_IN_n   = uio_in[6]; // Consolidated active-low safety fault line

    // Force both Yosys and OpenROAD to preserve this exact net name 
    // and prevent it from being renamed or optimized during flattening.
    (* keep = 1, dont_touch = 1 *) wire sys_clk;

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
    bit             stabilized_ci_n;

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
    anti_glitch_filter  #(
        .RESET_VALUE(1'b1)      // Forces a safe, idle-high state
    ) ci_filter (
        .clk              (phase_clk),     // Connect the system clock line
        .rst_n            (rst_n),         // Connect the global reset line
        .TESTMODE_n       (TESTMODE_n),    // Connect the full production test port
        .raw_signal_in    (core_signals.ci_n),
        .clean_signal_out (stabilized_ci_n)
    );

    // Evaluate master system override control flags
    // If any of them drop to 0, functional operations are disabled.
    wire system_disabled = (FLG_IN_n == 1'b0) || (ena == 1'b0) || (rst_n == 1'b0);
    wire raw_flg_n = !system_disabled;
    wire FLG_n;

    // 3. Reporrt faults via the delay filter circuit
    anti_glitch_filter  #(
        .RESET_VALUE(1'b0)      // Forces an active fault-asserted low state
    ) flg_filter (
        .clk              (phase_clk),     // Connect the system clock line
        .rst_n            (rst_n),         // Connect the global reset line
        .TESTMODE_n       (TESTMODE_n),    // Connect the full production test port
        .raw_signal_in    (raw_flg_n),
        .clean_signal_out (FLG_n)
    );

    // Move the selection outside into a continuous assignment
    wire a11 = pmod1_bus.addr[0]; 

    /* verilator lint_off UNUSED */
    wire unused_p3_b7 = core_signals.unused_p3_b7;
    wire FLG_n_p3 = core_signals.FLG_n;
    /* verilator lint_on UNUSED */

    // -------------------------------------------------------------------------
    // HARDWARE DIVIDER REGISTER ARRAY INSTANTIATION (SIGNAL_DIVIDER_BY_4)
    // -------------------------------------------------------------------------
    wire divided_ci_n;
    wire divided_s4_n;
    wire divided_io_n;
    wire divided_os_n;
    wire divided_basic_n;
    wire divided_s5_n;

    // A. CAS Inhibit / Refresh Divider Configuration
    signal_divider_by_4 ci_divider (
        .clk        (phase_clk),
        .rst_n      (rst_n),
        .signal_in  (stabilized_ci_n),
        .signal_out (divided_ci_n)
    );

    // B. Expansion Cartridge S4 Divider Configuration
    signal_divider_by_4 s4_divider (
        .clk        (phase_clk),
        .rst_n      (rst_n),
        .signal_in  (core_signals.s4_n),
        .signal_out (divided_s4_n)
    );

    // C. Hardware I/O Select Divider Configuration
    signal_divider_by_4 io_divider (
        .clk        (phase_clk),
        .rst_n      (rst_n),
        .signal_in  (core_signals.io_n),
        .signal_out (divided_io_n)
    );

    // D. OS Kernel ROM Select Divider Configuration
    signal_divider_by_4 os_divider (
        .clk        (phase_clk),
        .rst_n      (rst_n),
        .signal_in  (core_signals.os_n),
        .signal_out (divided_os_n)
    );

    // E. BASIC Interpreter ROM Select Divider Configuration
    signal_divider_by_4 basic_divider (
        .clk        (phase_clk),
        .rst_n      (rst_n),
        .signal_in  (core_signals.basic_n),
        .signal_out (divided_basic_n)
    );

    // F. Expansion Cartridge S5 Divider Configuration
    signal_divider_by_4 s5_divider (
        .clk        (phase_clk),
        .rst_n      (rst_n),
        .signal_in  (core_signals.s5_n),
        .signal_out (divided_s5_n)
    );

    // =========================================================================
    // PHYSICAL ROUTING MATRIX (Streamlined & Optimized)
    // =========================================================================
    
    // --- Pmod 2 Outputs Mapping ---
    // TRIGGER_OUT maps explicitly to Bit 5. It bypasses all dividers (Instantaneous).
    assign uio_out = {2'b00, a11, 5'b00000};

    // --- Dedicated Boundary Output Register for the Safety Flag ---
    logic flg_out_reg;
    always_ff @(posedge phase_clk or negedge rst_n) begin
        if (!rst_n) begin
            flg_out_reg <= 1'b0; // Resets safely to active fault-asserted low
        end else begin
            flg_out_reg <= FLG_n; // Latches the anti-glitch filter status
        end
    end

    // --- Pmod 3 Outputs Mapping (uo_out) ---
    // Cleared of redundant !rst_n logic loops. system_disabled handles the entire cutoff.
    assign uo_out[7] = 1'b0;                                                // Static ground tie-off
    assign uo_out[6] = flg_out_reg;                                         // Driven by a clean flip-flop!
    assign uo_out[5] = system_disabled ? 1'b1 : divided_s4_n;               // S4 Expansion Select Lane
    assign uo_out[4] = system_disabled ? 1'b1 : divided_io_n;               // Hardware I/O Select Lane
    assign uo_out[3] = system_disabled ? 1'b1 : divided_ci_n;               // Synchronized CAS Inhibit Lane
    assign uo_out[2] = system_disabled ? 1'b1 : divided_os_n;               // OS Kernel Selected Memory Lane
    assign uo_out[1] = system_disabled ? 1'b1 : divided_basic_n;            // BASIC Interpreter Selected Memory Lane
    assign uo_out[0] = system_disabled ? 1'b1 : divided_s5_n;               // S5 Expansion Select Lane

endmodule

`endif