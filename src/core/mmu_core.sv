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

// 1. Import everything from the package namespace
//import mmu_defs::*;

module mmu_core (
    input  pmod1_inputs_t  core_in, 
    input             ren,
    input             ref_n,
    input             mpd_n,
    input             be_n,
    output pmod3_outputs_t core_out  // Directly maps to the 8-bit output profile!
);

    // =========================================================================
    // LOCAL LOGIC HOOKS & VECTOR EXTRACTION
    // =========================================================================
    logic        a11;
    logic        a12;
    logic        a13;
    logic        a14;
    logic        a15;
    logic        map_n;
    logic        rd4;
    logic        rd5;

    // Direct slice mapping matching your MSB->LSB layout definitions
    assign a11   = core_in.addr[0];
    assign a12   = core_in.addr[1];
    assign a13   = core_in.addr[2];
    assign a14   = core_in.addr[3];
    assign a15   = core_in.addr[4];
    
    assign rd5   = core_in.control_bits[2];
    assign rd4   = core_in.control_bits[1];
    assign map_n = core_in.control_bits[0];

    // =========================================================================
    // COMBINATORIAL DECODING ENGINE
    // =========================================================================
    always_comb begin
        // 1. PLACE ALL VARIABLE DECLARATIONS AT THE VERY TOP
        logic local_os_n;

        // 1. Establish Hard Core Pull-Up Defaults (Active-Low Inactive Baseline)
        core_out.unused_p3_b7 = 1'b0; // Static Ground Tie-off
        core_out.FLG_n        = 1'b1;
        core_out.s4_n         = 1'b1;
        core_out.s5_n         = 1'b1;
        core_out.basic_n      = 1'b1;
        core_out.io_n         = 1'b1;
        core_out.os_n         = 1'b1;
        core_out.ci_n         = 1'b1;

        // Extract the raw OS decoding state into a temporary 
        // local tracking variable. This breaks the implicit loop on core_out.os_n.
        local_os_n = 1'b1;

        // 2. Evaluate /S4 Expansion Right Cartridge Select
        if (!a13 && !a14 && a15 && rd4 && ref_n) begin
            core_out.s4_n = 1'b0;
        end

        // 3. Evaluate /S5 Expansion Left Cartridge Select
        if (a13 && !a14 && a15 && rd5 && ref_n) begin
            core_out.s5_n = 1'b0;
        end

        // 4. Evaluate /BASIC CS Memory Space Decode
        if (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) begin
            core_out.basic_n = 1'b0;
        end

        // 5. Evaluate /IO Peripheral Space Decode ($D000)
        if (!a11 && a12 && !a13 && a14 && a15 && ref_n) begin
            core_out.io_n = 1'b0;
        end

        // 6. Evaluate /OS Operating System ROM Decode
        if ( (a13 && a14 && a15 && ren && ref_n) ||
             (!a12 && a14 && a15 && ren && ref_n) ||
             (a11 && a12 && !a13 && a14 && a15 && ren && mpd_n && ref_n) ||
             (!a11 && a12 && !a13 && a14 && !a15 && ren && !map_n && ref_n) ) begin
            local_os_n  = 1'b0;
        end

         // Drive the clean output port net safely
        core_out.os_n = local_os_n;

        // 7. Evaluate /CI Clock Inhibit Generation
        // Reference local_os_n instead of core_out.os_n to smash the loop trap
        if ( (!a13 && !a14 && a15 && rd4 && ref_n) ||
             (a13 && !a14 && a15 && rd5 && ref_n) ||
             (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) ||
             (local_os_n == 1'b1) ||
             !(a11 && a12 && !a13 && a14 && a15 && ref_n) ||
             (!ref_n) ) begin
            core_out.ci_n = 1'b0;
        end
    end

endmodule
`endif