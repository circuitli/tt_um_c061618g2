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
    // Extract variables locally for clean, legible equation tracking
    wire [4:0] a     = core_in.addr;
    wire       rd5   = core_in.control_bits[2];
    wire       rd4   = core_in.control_bits[1];
    wire       map_n = core_in.control_bits[0];

    // -------------------------------------------------------------------------
    // FORMAL ASSUMPTIONS & ASSERTIONS (Procedural Immediate Block for Yosys)
    // -------------------------------------------------------------------------
    always @(*) begin
        // Constrain inputs to realistic known states
        assume_ren_known:   assume ($isunknown(ren) == 0);
        assume_ref_n_known: assume ($isunknown(ref_n) == 0);
        assume_mpd_n_known: assume ($isunknown(mpd_n) == 0);
        assume_be_n_known:  assume ($isunknown(be_n) == 0);
        assume_addr_known:  assume ($isunknown(a) == 0);

        // 1. BASIC ROM Selection Rule: Maps strictly to $A000-$BFFF (5'h14 - 5'h17)
        if (map_n && be_n && (a >= 5'h14) && (a <= 5'h17)) begin
            assert_basic_rom: assert (core_out.basic_n == 0);
        end
        
        if (!map_n || !be_n || (a < 5'h14) || (a > 5'h17)) begin
            assert_basic_rom_disabled: assert (core_out.basic_n == 1);
        end

        // 2. OS ROM Selection Rule: Maps strictly to $E000-$FFFF (5'h1C - 5'h1F)
        if (map_n && ren && (a >= 5'h1C) && (a <= 5'h1F)) begin
            assert_os_rom: assert (core_out.os_n == 0);
        end
        
        if (!map_n || !ren || (a < 5'h1C) || (a > 5'h1F)) begin
            assert_os_rom_disabled: assert (core_out.os_n == 1);
        end

        // 3. HARDWARE I/O Selection Rule: Maps to exactly $D000 area (5'h1A)
        if (map_n && ren && (a == 5'h1A)) begin
            assert_io_select: assert (core_out.io_n == 0);
        end
        
        if (!map_n || !ren || (a != 5'h1A)) begin
            assert_io_select_disabled: assert (core_out.io_n == 1);
        end

        // 4. RAM Bank Selection Rules (Checking safe deployment of rd4 and rd5 inputs)
        if (map_n && mpd_n && rd4 && (a == 5'h08)) begin
            assert_s4_bank: assert (core_out.s4_n == 0);
        end
        
        if (!map_n || !mpd_n || !rd4 || (a != 5'h08)) begin
            assert_s4_bank_disabled: assert (core_out.s4_n == 1);
        end
        
        if (map_n && be_n && rd5 && (a == 5'h14)) begin
            assert_s5_bank: assert (core_out.s5_n == 0);
        end

        if (!map_n || !be_n || !rd5 || (a != 5'h14)) begin
            assert_s5_bank_disabled: assert (core_out.s5_n == 1);
        end

        // 5. Clock Inhibit / Wait State Generation
        if (map_n && (a == 5'h1A) && !ref_n) begin
            assert_ci_active: assert (core_out.ci_n == 0);
        end
        
        if (!map_n || (a != 5'h1A) || ref_n) begin
            assert_ci_inactive: assert (core_out.ci_n == 1);
        end

        // 6. SANITY SAFETY CHECK: Global Mutual Exclusion Verification matrix
        assert_os_basic_exclusion: assert (!(core_out.os_n == 0 && core_out.basic_n == 0));
        assert_os_io_exclusion:    assert (!(core_out.os_n == 0 && core_out.io_n == 0));
        assert_basic_io_exclusion: assert (!(core_out.basic_n == 0 && core_out.io_n == 0));
        assert_s4_s5_exclusion:    assert (!(core_out.s4_n == 0 && core_out.s5_n == 0));
    end

endmodule

// Bind statement to cleanly inject the formal module properties into production RTL
bind mmu_core mmu_core_formal i_mmu_core_formal (
    .core_in  (core_in),
    .ren      (ren),
    .ref_n    (ref_n),
    .mpd_n    (mpd_n),
    .be_n     (be_n),
    .core_out (core_out)
);

`endif
