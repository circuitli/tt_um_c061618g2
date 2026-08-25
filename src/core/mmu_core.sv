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

module mmu_core #(
    parameter int FILTER_STAGES = 4
)(
    input  pmod1_inputs_t  core_in, 
    input                  ren, ref_n, mpd_n, be_n,
    output pmod3_outputs_t core_out
);

    // Single-line unpack preserves meaningful signal names perfectly
    logic a11, a12, a13, a14, a15, map_n, rd4, rd5;
    assign {rd5, rd4, map_n} = core_in.control_bits;
    assign {a15, a14, a13, a12, a11} = core_in.addr;

    // Compact vector structures
    logic [6:0] raw_signals, clean_signals;
    logic raw_flg_n, raw_s4_n, raw_s5_n, raw_basic_n, raw_io_n, raw_os_n, raw_ci_n, local_os_n;

    assign raw_signals = {raw_flg_n, raw_s4_n, raw_io_n, raw_ci_n, raw_os_n, raw_basic_n, raw_s5_n};

    always_comb begin
        // Hard Core Pull-Up Defaults
        raw_flg_n   = 1'b1;
        raw_s4_n    = 1'b1;
        raw_s5_n    = 1'b1;
        raw_basic_n = 1'b1;
        raw_io_n    = 1'b1;
        raw_ci_n    = 1'b1;
        local_os_n  = 1'b1;

        // Evaluate /S4 Expansion Right Cartridge Select
        if (!a13 && !a14 && a15 && rd4 && ref_n) begin
            raw_s4_n = 1'b0;
        end

        // Evaluate /S5 Expansion Left Cartridge Select
        if (a13 && !a14 && a15 && rd5 && ref_n) begin
            raw_s5_n = 1'b0;
        end

        // Evaluate /BASIC CS Memory Space Decode
        if (a13 && !a14 && a15 && !rd5 && !be_n && ref_n) begin
            raw_basic_n = 1'b0;
        end

        // Evaluate /IO Peripheral Space Decode ($D000)
        if (!a11 && a12 && !a13 && a14 && a15 && ref_n) begin
            raw_io_n = 1'b0;
        end

        // Evaluate /OS Operating System ROM Decode
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

    // =========================================================================
    // PHYSICAL GLITCH ISOLATION LAYER (BANK INTEGRATION)
    // =========================================================================
    async_glitch_filter_bank #(.WIDTH(7), 
                               .STAGES(FILTER_STAGES)
    ) u_mmu_filter_bank (
        .rst_n    (1'b1), 
        .async_in (raw_signals), 
        .async_out(clean_signals)
    );

    // =========================================================================
    // CLEAN TYPE-CAST OUTPUT MAPPING
    // =========================================================================
    assign core_out = pmod3_outputs_t'({1'b0, clean_signals});

endmodule

`default_nettype wire
`endif // MMU_CORE_SVH
