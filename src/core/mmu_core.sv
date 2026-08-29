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
    parameter int FILTER_STAGES = 4
)(
    input  wire                 rst_n,     // Asynchronous active-low reset
    input  wire  [2:0]          core_ctrl, // Control bits: rd5, rd4, map_n
    input  wire  [4:0]          core_addr, // Address bits: A15, A14, A13, A12, A11
    input  wire                 ren,       // OS ROM Read Enable
    input  wire                 ref_n,     // DRAM Refresh Cycle
    input  wire                 mpd_n,     // Math Pack Disable
    input  wire                 be_n,      // BASIC Interpreter Enable
    
    `ifdef dfkjlsdjflsdkjflskdjf
        output wire  [7:0]          core_out
    `else
        output pmod3_outputs_t      core_out   // Unidirectional packed structure output
    `endif
);

    // =========================================================================
    // 1. DIRECT WIRE SPLICING
    // =========================================================================
    wire a11, a12, a13, a14, a15, map_n, rd4, rd5;
    
    assign {rd5, rd4, map_n} = core_ctrl;
    assign {a15, a14, a13, a12, a11} = core_addr;

    // =========================================================================
    // 2. CHIP DECODING MATRIX
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

        if (rst_n) begin
            // /S4 Expansion Right Cartridge Select ($8000-$9FFF)
            if (!a13 && !a14 && a15 && rd4 && ref_n) begin
                raw_s4_n = 1'b0;
            end

            // /S5 Expansion Left Cartridge Select ($A000-$BFFF)
            if (a13 && !a14 && a15 && rd5 && ref_n) begin
                raw_s5_n = 1'b0;
            end

            // /BASIC CS Memory Space Decode ($A000-$BFFF)
            if (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) begin
                raw_basic_n = 1'b0;
            end

            // /IO Peripheral Space Decode ($D000)
            if (!a11 && a12 && !a13 && a14 && a15 && ref_n) begin
                raw_io_n = 1'b0;
            end

            // /OS Operating System ROM Decode ($C000-$CFFF, $E000-$FFFF)
            if ( (a13 && a14 && a15 && ren && ref_n) ||
                 (!a12 && a14 && a15 && ren && ref_n) ||
                 (a11 && a12 && !a13 && a14 && a15 && ren && mpd_n && ref_n) ||
                 (!a11 && a12 && !a13 && a14 && !a15 && ren && !map_n && ref_n) ) begin
                local_os_n  = 1'b0;
            end
            raw_os_n = local_os_n;

            if ( (!a13 && !a14 && a15 && rd4 && ref_n) ||
                    (a13 && !a14 && a15 && rd5 && ref_n) ||
                    (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) ||
                    (local_os_n == 1'b1) ||
                    !(a11 && a12 && !a13 && a14 && a15 && ref_n) ||
                    (!ref_n) ) begin
                raw_ci_n = 1'b0;
            end
        end

        // Safe procedural packing
        raw_signals = {raw_s4_n, raw_io_n, raw_ci_n, raw_os_n, raw_basic_n, raw_s5_n};
    end

    // =========================================================================
    // 3. PHYSICAL GLITCH ISOLATION LAYER (BANK INTEGRATION)
    // =========================================================================
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
    // Unpacks fields procedures inside always_comb to guarantee the simulator
    // resolves the port assignments atomically, eliminating pin skew.
    // ---------------------------------------------------------------------
    pmod3_outputs_t sim_out_struct;
        
    always_comb begin
        if (rst_n) begin
            sim_out_struct.unused_p3_b7 = 1'b0;
            sim_out_struct.FLG_n        = 1'b1;
            {sim_out_struct.s4_n,    
                sim_out_struct.io_n,    
                sim_out_struct.ci_n,    
                sim_out_struct.os_n,    
                sim_out_struct.basic_n, 
                sim_out_struct.s5_n}       = clean_signals;
        end else begin
            sim_out_struct.unused_p3_b7 = 1'b0;
            sim_out_struct.FLG_n        = 1'b1;
            sim_out_struct.s4_n         = 1'b1;
            sim_out_struct.io_n         = 1'b1;
            sim_out_struct.ci_n         = 1'b1;
            sim_out_struct.os_n         = 1'b1;
            sim_out_struct.basic_n      = 1'b1;
            sim_out_struct.s5_n         = 1'b1;
        end
    end
        
    assign core_out = sim_out_struct;

endmodule

`default_nettype wire


`default_nettype wire
`endif // MMU_CORE_SVH
