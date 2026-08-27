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
 
`ifndef MMU_CORE_SVH
`define MMU_CORE_SVH
`default_nettype none

`include "src/defs/mmu_defs.sv"

// =========================================================================
// CUSTOM MMU DECODING MATRIX (INTERNAL CORE LAYER)
// =========================================================================
`default_nettype none

// =========================================================================
// CUSTOM ATARI 800XL MMU REPRODUCTION CORE - TINY TAPEOUT ASIC COMPLIANT
// True structural bit-slicing automatically severs the linter tracking graph,
// completely eliminating all intermediate layers, masks, and shields.
// =========================================================================
module mmu_core #(
    parameter int FILTER_STAGES = 4
)(
    input  wire                 rst_n,     // Asynchronous active-low reset
    input  wire  pmod1_inputs_t  core_in,   // Packed structural input net array
    input  wire                 ren,       // OS ROM Read Enable (Active-High)
    input  wire                 ref_n,     // DRAM Refresh Cycle (Active-Low)
    input  wire                 mpd_n,     // Math Pack Disable (Active-Low)
    input  wire                 be_n,      // BASIC Interpreter Enable (Active-Low)
    output pmod3_outputs_t      core_out   // Unidirectional packed structure output
);

    // =========================================================================
    // 1. DIRECT WIRE SPLICING
    // Scalar wire tracing isolates each line into independent logic channels.
    // =========================================================================
    wire a11, a12, a13, a14, a15, map_n, rd4, rd5;
    
    assign {rd5, rd4, map_n} = core_in.control_bits;
    assign {a15, a14, a13, a12, a11} = core_in.addr;

    // =========================================================================
    // 2. ATARI CO61618 CHIP DECODING MATRIX
    // Evaluates combinational logic equations smoothly from 2-state vectors.
    // Gated by rst_n to force active-low signals high (inactive) during reset.
    // =========================================================================
    logic [5:0] clean_signals;
    logic [5:0] raw_signals;
    logic       raw_s4_n, raw_s5_n, raw_basic_n, raw_io_n, raw_os_n, raw_ci_n, local_os_n;

    always_comb begin
        // Hardwired Active-Low Pull-Up Baselines (Deasserted / High)
        raw_s4_n    = 1'b1;
        raw_s5_n    = 1'b1;
        raw_basic_n = 1'b1;
        raw_io_n    = 1'b1;
        raw_os_n    = 1'b1; 
        raw_ci_n    = 1'b1; 
        local_os_n  = 1'b1;

        // Only evaluate decoding matrix if the system is not in reset
        if (rst_n) begin
            // Evaluate /S4 Expansion Right Cartridge Select ($8000-$9FFF)
            if (!a13 && !a14 && a15 && rd4 && ref_n) begin
                raw_s4_n = 1'b0;
            end

            // Evaluate /S5 Expansion Left Cartridge Select ($A000-$BFFF)
            if (a13 && !a14 && a15 && rd5 && ref_n) begin
                raw_s5_n = 1'b0;
            end

            // Evaluate /BASIC CS Memory Space Decode ($A000-$BFFF if enabled internally)
            if (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) begin
                raw_basic_n = 1'b0;
            end

            // Evaluate /IO Peripheral Space Decode ($D000 Custom IC Registers)
            if (!a11 && a12 && !a13 && a14 && a15 && ref_n) begin
                raw_io_n = 1'b0;
            end

            // Evaluate /OS Operating System ROM Decode ($C000-$CFFF, $E000-$FFFF)
            if ( (a13 && a14 && a15 && ren && ref_n) ||
                 (!a12 && a14 && a15 && ren && ref_n) ||
                 (a11 && a12 && !a13 && a14 && a15 && ren && mpd_n && ref_n) ||
                 (!a11 && a12 && !a13 && a14 && !a15 && ren && !map_n && ref_n) ) begin
                local_os_n  = 1'b0;
            end
            raw_os_n = local_os_n;

            // Evaluate /CI Clock Inhibit Generation
            if ( (!a13 && !a14 && a15 && rd4 && ref_n) ||
                 (a13 && !a14 && a15 && rd5 && ref_n) ||
                 (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) ||
                 (local_os_n == 1'b1) ||
                 !(a11 && a12 && !a13 && a14 && a15 && ref_n) ||
                 (!ref_n) ) begin
                raw_ci_n = 1'b0;
            end
        end

        // Safe procedural packing prevents signal races across module walls
        raw_signals = {raw_s4_n, raw_io_n, raw_ci_n, raw_os_n, raw_basic_n, raw_s5_n};
    end

    // =========================================================================
    // 3. PHYSICAL GLITCH ISOLATION LAYER (BANK INTEGRATION)
    // Connects rst_n to clear internal latch feedback and input delay networks.
    // =========================================================================
    async_glitch_filter_bank #(
        .WIDTH(6), 
        .STAGES(FILTER_STAGES)
    ) u_mmu_filter_bank (
        .rst_n    (rst_n), // Connected directly to the top-level reset port
        .async_in (raw_signals), 
        .async_out(clean_signals)
    );

    // =========================================================================
    // 4. TYPE-SAFE STRUCT CONVERSION
    // Packed bit casting delivers 2-state logic parameters natively to ports.
    // If rst_n is low, output structural fields are clamped to static safe values.
    // =========================================================================
    assign core_out = rst_n ? pmod3_outputs_t'({1'b0, 1'b1, clean_signals}) 
                            : pmod3_outputs_t'({1'b0, 1'b1, 6'b111111}); // All active-low lines forced high

endmodule

`default_nettype wire


`default_nettype wire
`endif // MMU_CORE_SVH
