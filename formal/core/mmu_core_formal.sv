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

module mmu_core_formal (
    input  pmod1_inputs_t  core_in, 
    input                  ren,
    input                  ref_n,
    input                  mpd_n,
    input                  be_n,
    input  pmod3_outputs_t core_out
);
    // =========================================================================
    // LOCAL WIRE ALIAS EXTRACTIONS
    // =========================================================================
    wire a11   = core_in.addr[0];
    wire a12   = core_in.addr[1];
    wire a13   = core_in.addr[2];
    wire a14   = core_in.addr[3];
    wire a15   = core_in.addr[4];
    
    wire rd5   = core_in.control_bits[2];
    wire rd4   = core_in.control_bits[1];
    wire map_n = core_in.control_bits[0];

    // =========================================================================
    // FORMAL ASSERTIONS GENERATION (Derived from 1984 Atari MMU Equations)
    // =========================================================================
    always @(*) begin
        // 1. Validate Fixed Output Baselines
        assert_unused_p3_b7: assert (core_out.unused_p3_b7 == 1'b0);
        assert_loop_out:     assert (core_out.LOOP_OUT == 1'b1);

        // 2. Validate /S4 Cartridge Range Selector Check
        if (!a13 && !a14 && a15 && rd4 && ref_n) begin
            assert_s4_active: assert (core_out.s4_n == 1'b0);
        end else begin
            assert_s4_inactive: assert (core_out.s4_n == 1'b1);
        end

        // 3. Validate /S5 Cartridge Range Selector Check
        if (a13 && !a14 && a15 && rd5 && ref_n) begin
            assert_s5_active: assert (core_out.s5_n == 1'b0);
        end else begin
            assert_s5_inactive: assert (core_out.s5_n == 1'b1);
        end

        // 4. Validate /BASIC ROM Memory Space Selector Check
        if (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) begin
            assert_basic_active: assert (core_out.basic_n == 1'b0);
        end else begin
            assert_basic_inactive: assert (core_out.basic_n == 1'b1);
        end

        // 5. Validate /IO Peripheral Select Check
        if (!a11 && a12 && !a13 && a14 && a15 && ref_n) begin
            assert_io_active: assert (core_out.io_n == 1'b0);
        end else begin
            assert_io_inactive: assert (core_out.io_n == 1'b1);
        end

        // 6. Validate /OS Operating System ROM Selector Check
        if ((a13 && a14 && a15 && ren && ref_n) ||
            (!a12 && a14 && a15 && ren && ref_n) ||
            (a11 && a12 && !a13 && a14 && a15 && ren && mpd_n && ref_n) ||
            (!a11 && a12 && !a13 && a14 && !a15 && ren && !map_n && ref_n)) begin
            assert_os_active: assert (core_out.os_n == 1'b0);
        end else begin
            assert_os_inactive: assert (core_out.os_n == 1'b1);
        end

        // 7. Validate /CI Clock Inhibit Evaluation Check
        if ((!a13 && !a14 && a15 && rd4 && ref_n) ||
            (a13 && !a14 && a15 && rd5 && ref_n) ||
            (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) ||
            (core_out.os_n == 1'b0) ||
            (!a11 && a12 && !a13 && a14 && a15 && ref_n) ||
            (!ref_n)) begin
            assert_ci_active: assert (core_out.ci_n == 1'b0);
        end else begin
            assert_ci_inactive: assert (core_out.ci_n == 1'b1);
        end
    end

endmodule

// Bind declaration mapping structural signals cleanly into the tracking workspace
bind mmu_core mmu_core_formal i_mmu_core_formal (
    .core_in  (core_in),
    .ren      (ren),
    .ref_n    (ref_n),
    .mpd_n    (mpd_n),
    .be_n     (be_n),
    .core_out (core_out)
);

`endif

