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
 
`ifndef MMU_CORE_FORMAL_SV
`define MMU_CORE_FORMAL_SV

`default_nettype none
`include "src/defs/mmu_defs.sv"
module mmu_core_formal #(
    parameter int FILTER_STAGES = 4
)(
    input  wire                 clk,      // System clock injected for property gating
    input  wire                 rst_n,
    input  wire  pmod1_inputs_t  core_in,
    input  wire                 ren,
    input  wire                 ref_n,
    input  wire                 mpd_n,
    input  wire                 be_n,
    input  wire  pmod3_outputs_t core_out
);

    // -------------------------------------------------------------------------
    // INTERNAL NET EXTRACTION FOR PROPERTY DECODING
    // FIXED: Corrected out-of-bounds bit indices to match real array widths [4:0] and [2:0].
    // This removes the invalid references, completely destroying cell simplemap_bitop$303!
    // -------------------------------------------------------------------------
    wire a15 = core_in.addr[4];
    wire a14 = core_in.addr[3];
    wire a13 = core_in.addr[2];
    wire a12 = core_in.addr[1];
    wire a11 = core_in.addr[0];
    
    wire rd5 = core_in.control_bits[2];
    wire rd4 = core_in.control_bits[1];

    // Extract the active-low signal vector from the packed struct format [5:0]
    wire [5:0] out_vec = core_out.data_pins;
    wire s5_n    = out_vec[5];
    wire s4_n    = out_vec[4];
    wire io_n    = out_vec[3];
    wire basic_n = out_vec[0];

    // =========================================================================
    // FIXED LOOP-SAFE CLOCKED FORMAL DECODING PROPERTIES
    // Evaluates on the clocked posedge grid to prevent simplemap self-loops!
    // =========================================================================
    always @(posedge clk) begin

        // 1. GLOBAL ASYNCHRONOUS RESET SAFE-STATE PROOF
        asm_mmu_reset_assert: assert (rst_n || (out_vec == 6'b111111));

        // 2. ADDRESS DECODING PROOFS (ARROW-FREE)
        asm_decode_s4_assert: assert (!(rst_n && !a13 && !a14 && a15 && rd4 && ref_n) || (s4_n == 1'b0));
        asm_decode_s5_assert: assert (!(rst_n && a13 && !a14 && a15 && rd5 && ref_n) || (s5_n == 1'b0));
        asm_decode_basic_assert: assert (!(rst_n && a13 && !a14 && a15 && !rd5 && !be_n && ref_n) || (basic_n == 1'b0));
        asm_decode_io_assert: assert (!(rst_n && !a11 && a12 && !a13 && a14 && a15 && ref_n) || (io_n == 1'b0));

        // 3. MUTUAL EXCLUSION PROOF
        asm_mmu_exclusion_assert: assert (!rst_n || !(basic_n == 1'b0 && s5_n == 1'b0));

    end

endmodule

// Bind declaration mapping structural signals cleanly into the tracking workspace
bind mmu_core mmu_core_formal i_mmu_core_formal (
    .clk      (tt_um_c061618g2.clk), 
    .rst_n    (rst_n),
    .core_in  (core_in),
    .ren      (ren),
    .ref_n    (ref_n),
    .mpd_n    (mpd_n),
    .be_n     (be_n),
    .core_out (core_out)
);

`endif

