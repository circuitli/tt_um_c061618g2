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

    // Unpack the control bits internally from the incoming structured bus
    bit rd5;
    bit rd4;
    bit map_n;
    bit [4:0] a;

    assign rd5   = core_in.control_bits[2];
    assign rd4   = core_in.control_bits[1];
    assign map_n = core_in.control_bits[0];
    assign a     = core_in.addr;

    // =========================================================================
    // MMU COMBINATORIAL DECODING EQUATIONS
    // =========================================================================
    always_comb begin
        // Clear the entire output structure to a safe default state
        core_out = '1;

       // =========================================================================
        // MMU COMBINATORIAL DECODING EQUATIONS
        // =========================================================================
        // Address Conversions for Bits [15:11]:
        // $0800 -> 5'h01 (1)  |  $A000 -> 5'h14 (20) |  $D000 -> 5'h1A (26)
        // $BFFF -> 5'h17 (23) |  $D800 -> 5'h1B (27) |  $FFFF -> 5'h1F (31)
        // =========================================================================
        
        // BASIC ROM Selection: Maps to $A000-$BFFF (5'h14 to 5'h17)
        core_out.basic_n = !(map_n && (a >= 5'h14) && (a <= 5'h17) && ren);

        // OS ROM Selection: Maps to $D800-$FFFF (5'h1B and up)
        core_out.os_n    = !(map_n && (a >= 5'h1B) && ren);

        // HARDWARE CS (I/O) Selection: Maps strictly to $D000-$D7FF (5'h1A)
        core_out.io_n    = !(map_n && (a == 5'h1A) && ren);

        // --- RAM Bank Selection Lines ---
        core_out.s4_n    = !((a == 5'h08) && mpd_n && rd4); // $4000-$47FF area
        core_out.s5_n    = !((a == 5'h14) && be_n && rd5);  // $A000-$A7FF area override 

        // --- Dynamic Clock Inhibit / Wait State Request ---
        // Assert CI low if accessing the slow peripheral mapping matrices
        if ((a == 5'b11010) && !ref_n) begin
            core_out.ci_n = 1'b0; 
        end else begin
            core_out.ci_n = 1'b1; 
        end
    end
endmodule
`endif