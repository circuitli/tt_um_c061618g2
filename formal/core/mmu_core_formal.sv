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
 
`ifndef MMU_CORE_FORMAL_SV
`define MMU_CORE_FORMAL_SV

`default_nettype none
`include "src/defs/mmu_defs.sv"

`default_nettype none

module mmu_core_formal #(
    parameter int FILTER_STAGES = 4
)(
    input  wire                 clk,        // System clock injected for property gating
    input  wire                 rst_n,      // Asynchronous active-low reset
    input  wire  [2:0]          core_ctrl,  // Flat vector for control bits: rd5, rd4, map_n
    input  wire  [4:0]          core_addr,  // Flat vector for address bits: A15, A14, A13, A12, A11
    input  wire                 ren,        // OS ROM Read Enable
    input  wire                 ref_n,      // DRAM Refresh Cycle
    input  wire                 mpd_n,      // Math Pack Disable
    input  wire                 be_n,       // BASIC Interpreter Enable
    input  wire  pmod3_outputs_t core_out    // Packed structural output array
);

    // -------------------------------------------------------------------------
    // INTERNAL NET EXTRACTION FOR PROPERTY DECODING
    // FIXED: Maps inputs by index slices and extracts output terms directly by
    // their true struct field names to prevent any bit-ordering corruption!
    // -------------------------------------------------------------------------
    wire rd5   = core_ctrl[2];
    wire rd4   = core_ctrl[1];
    wire map_n = core_ctrl[0];

    wire a15   = core_addr[4];
    wire a14   = core_addr[3];
    wire a13   = core_addr[2];
    wire a12   = core_addr[1];
    wire a11   = core_addr[0];

    // Reference fields directly from the struct to mirror the hardware layout perfectly
    wire s5_n    = core_out.s5_n;
    wire basic_n = core_out.basic_n;
    wire os_n    = core_out.os_n;
    wire ci_n    = core_out.ci_n;
    wire io_n    = core_out.io_n;
    wire s4_n    = core_out.s4_n;

    // =========================================================================
    // FIXED LOOP-SAFE CLOCKED FORMAL DECODING PROPERTIES
    // =========================================================================
    always @(posedge gclk) begin

        // 1. GLOBAL ASYNCHRONOUS RESET SAFE-STATE PROOF
        // When rst_n is low, all active-low control output lines must be high (deasserted)
        asm_mmu_reset_assert: assert (rst_n || (
            s5_n    == 1'b1 && 
            basic_n == 1'b1 && 
            os_n    == 1'b1 && 
            ci_n    == 1'b1 && 
            io_n    == 1'b1 && 
            s4_n    == 1'b1
        ));

        // 2. ADDRESS DECODING PROOFS (ARROW-FREE)
        // /S4 Expansion Right Cartridge Select ($8000-$9FFF)
        asm_decode_s4_assert: assert (!(rst_n && !a13 && !a14 && a15 && rd4 && ref_n) || (s4_n == 1'b0));
        
        // /S5 Expansion Left Cartridge Select ($A000-$BFFF)
        asm_decode_s5_assert: assert (!(rst_n && a13 && !a14 && a15 && rd5 && ref_n) || (s5_n == 1'b0));
        
        // /BASIC CS Memory Space Decode ($A000-$BFFF if enabled internally)
        asm_decode_basic_assert: assert (!(rst_n && a13 && !a14 && a15 && !rd5 && !be_n && ref_n) || (basic_n == 1'b0));
        
        // /IO Peripheral Space Decode ($D000 Custom IC Registers)
        asm_decode_io_assert: assert (!(rst_n && !a11 && a12 && !a13 && a14 && a15 && ref_n) || (io_n == 1'b0));

        // 3. MUTUAL EXCLUSION PROOF
        asm_mmu_exclusion_assert: assert (!rst_n || !(basic_n == 1'b0 && s5_n == 1'b0));

    end

endmodule

// Bind declaration mapping structural signals cleanly into the tracking workspace
bind mmu_core mmu_core_formal i_mmu_core_formal (
    .clk      (clk), // Pulls system clock from top-level to gate properties
    .rst_n    (rst_n),
    .core_ctrl (core_ctrl),           // Maps flat [2:0] control vector
    .core_addr (core_addr),           // Maps flat [4:0] address slice vector    .ren      (ren),
    .ref_n    (ref_n),
    .mpd_n    (mpd_n),
    .be_n     (be_n),
    .core_out (core_out)
);

`endif
