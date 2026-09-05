/*
 * Copyright 2026 circuitli (https://github.com)
 *
 * Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://cern-ohl.web.cern.ch/
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
`include "src/module/async_glitch_filter_bank.sv"

// =========================================================================
// CUSTOM MMU DECODING MATRIX (INTERNAL CORE LAYER)
// =========================================================================
`default_nettype none

// =========================================================================
// CUSTOM MMU REPRODUCTION CORE - TINY TAPEOUT ASIC COMPLIANT
// True structural bit-slicing automatically severs the linter tracking graph,
// completely eliminating all intermediate layers, masks, and shields.
// =========================================================================
`default_nettype none
`timescale 1ns/1ps

module mmu_core #(
    parameter int FILTER_STAGES = 3
)(
    input  wire                 rst_n,     // Asynchronous active-low reset
    input  wire  [2:0]          core_ctrl, // Control bits: rd5, rd4, map_n
    input  wire  [4:0]          core_addr, // Address bits: A15, A14, A13, A12, A11
    input  wire                 ren,       // OS ROM Read Enable
    input  wire                 ref_n,     // DRAM Refresh Cycle
    input  wire                 mpd_n,     // Math Pack Disable
    input  wire                 be_n,      // BASIC Interpreter Enable
    output pmod3_outputs_t      core_out   // Unidirectional packed structure output
);

    // =========================================================================
    // 1. DIRECT WIRE SPLICING
    // =========================================================================
    wire a11, a12, a13, a14, a15, map_n, rd4, rd5;
    
    assign {rd5, rd4, map_n} = core_ctrl;
    assign {a15, a14, a13, a12, a11} = core_addr;

        // =========================================================================
    // 1. DIRECT WIRE SPLICING
    // =========================================================================
    wire a11, a12, a13, a14, a15, map_n, rd4, rd5;
    
    assign {rd5, rd4, map_n} = core_ctrl;
    assign {a15, a14, a13, a12, a11} = core_addr;

    // =========================================================================
    // 2. CHIP DECODING MATRIX (PURE CONTINUOUS HARDWARE NETS)
    // By calculating the expressions completely flatly as continuous wires,
    // Yosys is structurally forbidden from inferring sequential logic!
    // =========================================================================
    wire raw_s4_n, raw_s5_n, raw_basic_n, raw_io_n, raw_os_n, raw_ci_n;

    // /S4 Expansion Right Cartridge Select ($8000-$9FFF)
    assign raw_s4_n = (rst_n && (!a13 && !a14 && a15 && rd4 && ref_n)) ? 1'b0 : 1'b1;

    // /S5 Expansion Left Cartridge Select ($A000-$BFFF)
    assign raw_s5_n = (rst_n && (a13 && !a14 && a15 && rd5 && ref_n)) ? 1'b0 : 1'b1;

    // /BASIC ROM Select ($A000-$BFFF)
    assign raw_basic_n = (rst_n && (a13 && !a14 && a15 && !rd5 && !be_n && ref_n)) ? 1'b0 : 1'b1;

    // /IO Hardware Peripheral Block Select ($D400-$D7FF)
    assign raw_io_n = (rst_n && (!a11 && a12 && !a13 && a14 && a15 && ref_n)) ? 1'b0 : 1'b1;

    // /OS ROM Controller Matrix ($E000-$FFFF & Shadows)
    assign raw_os_n = (rst_n && (
        (a13 && a14 && a15 && ren && ref_n) ||
        (!a12 && a14 && a15 && ren && ref_n) ||
        (a11 && a12 && !a13 && a14 && a15 && ren && mpd_n && ref_n) ||
        (!a11 && a12 && !a13 && a14 && !a15 && ren && !map_n && ref_n)
    )) ? 1'b0 : 1'b1;

    // /CI Active-Low Fallback
    assign raw_ci_n = (rst_n && (
        (!a13 && !a14 && a15 && rd4 && ref_n) ||
        (a13 && !a14 && a15 && rd5 && ref_n) ||
        (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) ||
        (raw_os_n == 1'b1) ||
        (!a11 && a12 && !a13 && a14 && a15 && ref_n) ||
        (!ref_n)
    )) ? 1'b0 : 1'b1;

    wire [5:0] raw_signals;
    assign raw_signals = {raw_s4_n, raw_io_n, raw_ci_n, raw_os_n, raw_basic_n, raw_s5_n};

    // =========================================================================
    // 3. PHYSICAL GLITCH ISOLATION LAYER (BANK INTEGRATION)
    // =========================================================================
    wire [5:0] clean_signals;

    async_glitch_filter_bank #(
        .WIDTH(6), 
        .STAGES(FILTER_STAGES)
    ) u_mmu_filter_bank (
        .rst_n    (rst_n), 
        .async_in (raw_signals), 
        .async_out(clean_signals)
    );

    // ---------------------------------------------------------------------
    // HAZARD-FREE SIMULATION STRUCT MAPPING
    // We assign everything through continuous 'assign' nets!
    // This strips out procedural struct block state retention and completely 
    // forces Yosys to view the output as a pure combinational wire grid.
    // =========================================================================
    wire s4_filtered, io_filtered, ci_filtered, os_filtered, basic_filtered, s5_filtered;
    assign {s4_filtered, io_filtered, ci_filtered, os_filtered, basic_filtered, s5_filtered} = clean_signals;

    wire out_s4    = rst_n ? s4_filtered    : 1'b1;
    wire out_io    = rst_n ? io_filtered    : 1'b1;
    wire out_ci    = rst_n ? ci_filtered    : 1'b1;
    wire out_os    = rst_n ? os_filtered    : 1'b1;
    wire out_basic = rst_n ? basic_filtered : 1'b1;
    wire out_s5    = rst_n ? s5_filtered    : 1'b1;

    // Assign the entire packed struct ATOMICALLY 
    // in one single shot. This prevents Yosys from parsing field slices 
    // and eliminates register inference completely!
    assign core_out = {
        1'b0,          // unused_p3_b7
        1'b1,          // FLG_n
        out_s4,        // s4_n
        out_io,        // io_n
        out_ci,        // ci_n
        out_os,        // os_n
        out_basic,     // basic_n
        out_s5         // s5_n
    };
        
endmodule

`default_nettype wire
`endif // MMU_CORE_SVH
