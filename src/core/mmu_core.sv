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
module mmu_core #(
    parameter int FILTER_STAGES = 4
)(
    input  pmod1_inputs_t  core_in, 
    input                  ren, ref_n, mpd_n, be_n,
    output pmod3_outputs_t core_out
);

    // 1. Unpack raw incoming inputs from the top-level wrapper interface
    logic raw_a11, raw_a12, raw_a13, raw_a14, raw_a15, raw_map_n, raw_rd4, raw_rd5;
    assign {raw_rd5, raw_rd4, raw_map_n} = core_in.control_bits;
    assign {raw_a15, raw_a14, raw_a13, raw_a12, raw_a11} = core_in.addr;

    // 2. Scrubbed internal wires protected against uninitialized simulation states
    logic a11, a12, a13, a14, a15, map_n, rd4, rd5;
    logic safe_ren, safe_ref_n, safe_mpd_n, safe_be_n;

    always_comb begin
        // Address lines default to 1'b1 
        // to emulate the physical motherboard pull-up resistors on the bus.
        a11        = (raw_a11   === 1'bx || raw_a11   === 1'bz) ? 1'b1 : raw_a11;
        a12        = (raw_a12   === 1'bx || raw_a12   === 1'bz) ? 1'b1 : raw_a12;
        a13        = (raw_a13   === 1'bx || raw_a13   === 1'bz) ? 1'b1 : raw_a13;
        a14        = (raw_a14   === 1'bx || raw_a14   === 1'bz) ? 1'b1 : raw_a14;
        a15        = (raw_a15   === 1'bx || raw_a15   === 1'bz) ? 1'b1 : raw_a15;
        
        // Active-low controls default to 1'b1 (deasserted/idle)
        map_n      = (raw_map_n === 1'bx || raw_map_n === 1'bz) ? 1'b1 : raw_map_n;
        rd4        = (raw_rd4   === 1'bx || raw_rd4   === 1'bz) ? 1'b1 : raw_rd4;
        rd5        = (raw_rd5   === 1'bx || raw_rd5   === 1'bz) ? 1'b1 : raw_rd5;
        safe_ref_n = (ref_n     === 1'bx || ref_n     === 1'bz) ? 1'b1 : ref_n;
        safe_mpd_n = (mpd_n     === 1'bx || mpd_n     === 1'bz) ? 1'b1 : mpd_n;
        safe_be_n  = (be_n      === 1'bx || be_n      === 1'bz) ? 1'b1 : be_n;
        
        // Active-high control defaults to 1'b0 (disabled/idle)
        safe_ren   = (ren       === 1'bx || ren       === 1'bz) ? 1'b0 : ren;
    end

    // 3. Compact vector structures and tracking nets
    logic [5:0] raw_signals, clean_signals;
    logic raw_s4_n, raw_s5_n, raw_basic_n, raw_io_n, raw_os_n, raw_ci_n, local_os_n;

    // =========================================================================
    // ATARI CO61618 DECODING MATRIX
    // =========================================================================
    always_comb begin
        // Hardwired Active-Low Pull-Up Defaults (Deasserted baseline)
        raw_s4_n    = 1'b1;
        raw_s5_n    = 1'b1;
        raw_basic_n = 1'b1;
        raw_io_n    = 1'b1;
        raw_os_n    = 1'b1; 
        raw_ci_n    = 1'b1; 
        local_os_n  = 1'b1;

        // Evaluate /S4 Expansion Right Cartridge Select ($8000-$9FFF)
        if (!a13 && !a14 && a15 && rd4 && safe_ref_n) begin
            raw_s4_n = 1'b0;
        end

        // Evaluate /S5 Expansion Left Cartridge Select ($A000-$BFFF)
        if (a13 && !a14 && a15 && rd5 && safe_ref_n) begin
            raw_s5_n = 1'b0;
        end

        // Evaluate /BASIC CS Memory Space Decode ($A000-$BFFF if enabled internally)
        if (a13 && !a14 && a15 && !rd5 && !safe_be_n && safe_ref_n) begin
            raw_basic_n = 1'b0;
        end

        // Evaluate /IO Peripheral Space Decode ($D000 Custom IC Registers)
        if (!a11 && a12 && !a13 && a14 && a15 && safe_ref_n) begin
            raw_io_n = 1'b0;
        end

        // Evaluate /OS Operating System ROM Decode ($C000-$CFFF, $E000-$FFFF)
        if ( (a13 && a14 && a15 && safe_ren && safe_ref_n) ||
             (!a12 && a14 && a15 && safe_ren && safe_ref_n) ||
             (a11 && a12 && !a13 && a14 && a15 && safe_ren && safe_mpd_n && safe_ref_n) ||
             (!a11 && a12 && !a13 && a14 && !a15 && safe_ren && !map_n && safe_ref_n) ) begin
            local_os_n  = 1'b0;
        end
        raw_os_n = local_os_n;

        // Evaluate /CI Clock Inhibit Generation
        if ( (!a13 && !a14 && a15 && rd4 && safe_ref_n) ||
             (a13 && !a14 && a15 && rd5 && safe_ref_n) ||
             (a13 && !a14 && a15 && !rd5 && !safe_be_n && safe_ref_n) ||
             (local_os_n == 1'b1) ||
             !(a11 && a12 && !a13 && a14 && a15 && safe_ref_n) ||
             (!safe_ref_n) ) begin
            raw_ci_n = 1'b0;
        end

        // =====================================================================
        // SAFE PROCEDURAL PACKING (ELIMINATES THE CONCURRENT EVALUATION RACE)
        // =====================================================================
        // Writing this inside the block ensures raw_signals is packed only after
        // all individual decoded bits have reached their final settled logic state.
        raw_signals = {raw_s4_n, raw_io_n, raw_ci_n, raw_os_n, raw_basic_n, raw_s5_n};
    end

    // =========================================================================
    // PHYSICAL GLITCH ISOLATION LAYER (BANK INTEGRATION)
    // =========================================================================
    async_glitch_filter_bank #(
        .WIDTH(6), 
        .STAGES(FILTER_STAGES)
    ) u_mmu_filter_bank (
        .rst_n    (1'b1), 
        .async_in (raw_signals), 
        .async_out(clean_signals)
    );

    // =========================================================================
    // CLEAN TYPE-CAST OUTPUT MAPPING
    // =========================================================================
    assign core_out = pmod3_outputs_t'({1'b0, 1'b1, clean_signals});

endmodule

`default_nettype wire
`endif // MMU_CORE_SVH
