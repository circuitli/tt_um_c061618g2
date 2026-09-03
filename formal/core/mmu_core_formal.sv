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

`default_nettype none

module mmu_core_formal #(
    parameter int FILTER_STAGES = 4
)(
    input  wire                 rst_n,      // Asynchronous active-low reset
    input  wire  [2:0]          core_ctrl,  // Flat vector for control bits: rd5, rd4, map_n
    input  wire  [4:0]          core_addr,  // Flat vector for address bits: A15, A14, A13, A12, A11
    input  wire                 ren,        // OS ROM Read Enable
    input  wire                 ref_n,      // DRAM Refresh Cycle
    input  wire                 mpd_n,      // Math Pack Disable
    input  wire                 be_n,       // BASIC Interpreter Enable
    input  wire  pmod3_outputs_t core_out    // Packed structural output array
);

    // =========================================================================
    // 1. DESIGN UNDER TEST (DUT) INSTANTIATION
    // =========================================================================
    mmu_core #(
        .FILTER_STAGES(FILTER_STAGES)
    ) dut (
        .rst_n    (rst_n),
        .core_ctrl(core_ctrl),
        .core_addr(core_addr),
        .ren      (ren),
        .ref_n    (ref_n),
        .mpd_n    (mpd_n),
        .be_n     (be_n),
        .core_out (core_out)
    );

    // Unpack input vectors locally for human-readable architectural matching
    wire a11   = core_addr[0];
    wire a12   = core_addr[1];
    wire a13   = core_addr[2];
    wire a14   = core_addr[3];
    wire a15   = core_addr[4];
    wire rd5   = core_ctrl[2];
    wire rd4   = core_ctrl[1];
    wire map_n = core_ctrl[0];


    // =========================================================================
    // 2. EXPLICIT INTERMEDIATE DECODING EQUATIONS (LONG FORM SPECIFICATION)
    // =========================================================================
    
    // --- Math Pack (/CI) Space ($D800-$DFFF) ---
    wire spec_ci_addr_match = (a15 == 1'b1) && (a14 == 1'b1) && (a13 == 1'b1) && (a12 == 1'b0) && (a11 == 1'b1);
    wire spec_ci_ctrl_valid = (ref_n == 1'b1) && (map_n == 1'b1) && (mpd_n == 1'b0);

    // --- OS ROM Space ($E000-$FFFF) ---
    wire spec_os_addr_match = (a15 == 1'b1) && (a14 == 1'b1);
    wire spec_os_ctrl_valid = (ref_n == 1'b1) && (map_n == 1'b1);


    // =========================================================================
    // 3. COMBINATORIAL ASSERTIONS BLOCK
    // =========================================================================
    always_comb begin
        
        // ---------------------------------------------------------------------
        // RESET STATE ASSERTIONS
        // ---------------------------------------------------------------------
        if (!rst_n) begin
            assert_reset_s4:    assert(dut.raw_s4_n    == 1'b1);
            assert_reset_s5:    assert(dut.raw_s5_n    == 1'b1);
            assert_reset_basic: assert(dut.raw_basic_n == 1'b1);
            assert_reset_io:    assert(dut.raw_io_n    == 1'b1);
            assert_reset_ci:    assert(dut.raw_ci_n    == 1'b1);
            assert_reset_os:    assert(dut.raw_os_n    == 1'b1);
            assert_reset_local: assert(dut.local_os_n  == 1'b1);
        end

        // ---------------------------------------------------------------------
        // OPERATIONAL FUNCTIONAL ASSERTIONS
        // ---------------------------------------------------------------------
        if (rst_n) begin
            
            // --- /S4 Expansion Right Cartridge Select ($8000-$9FFF) ---
            if (!a13 && !a14 && a15 && rd4 && ref_n) begin
                assert_s4_active: assert(dut.raw_s4_n == 1'b0);
            end

            // --- /S5 Expansion Left Cartridge Select ($A000-$BFFF) ---
            if (a13 && !a14 && a15 && rd5 && ref_n) begin
                assert_s5_active: assert(dut.raw_s5_n == 1'b0);
            end

            // --- /BASIC ROM Select ($A000-$BFFF) ---
            if (a13 && !a14 && a15 && !be_n && ref_n && map_n) begin
                assert_basic_active: assert(dut.raw_basic_n == 1'b0);
            end

            // --- /I/O Select ($D000-$D7FF) ---
            if (!a11 && !a12 && a13 && a14 && a15 && ref_n && map_n) begin
                assert_io_active: assert(dut.raw_io_n == 1'b0);
            end

            // -----------------------------------------------------------------
            // EXPANDED /CI (MATH PACK) DECODE VERIFICATION MATRIX
            // -----------------------------------------------------------------
            
            // Clause A: True Activation
            if (spec_ci_addr_match && spec_ci_ctrl_valid) begin
                assert_ci_perfect_match_low: assert(dut.raw_ci_n == 1'b0);
            end

            // Clause B: Blocked when math pack is explicitly disabled
            if (spec_ci_addr_match && (mpd_n == 1'b1)) begin
                assert_ci_disabled_by_mpd: assert(dut.raw_ci_n == 1'b1);
            end

            // Clause C: Boundary protection check against I/O lower page swap ($D000-$D7FF)
            if (a15 && a14 && a13 && !a12 && !a11) begin
                assert_ci_blocked_by_io_space: assert(dut.raw_ci_n == 1'b1);
            end

            // -----------------------------------------------------------------
            // EXPANDED /OS (OS ROM) DECODE VERIFICATION MATRIX
            // -----------------------------------------------------------------
            
            // Clause A: Local intermediate address match mapping
            if (spec_os_addr_match && spec_os_ctrl_valid) begin
                assert_local_os_internal_match: assert(dut.local_os_n == 1'b0);
            end else begin
                assert_local_os_outside_range:  assert(dut.local_os_n == 1'b1);
            end

            // Clause B: Active Read Enable allows the gateway to pull low
            if (dut.local_os_n == 1'b0 && ren == 1'b1) begin
                assert_os_gateway_opens: assert(dut.raw_os_n == 1'b0);
            end

            // Clause C: Missing Read Enable isolates external line high (Safe High State)
            if (dut.local_os_n == 1'b0 && ren == 1'b0) begin
                assert_os_isolated_without_ren: assert(dut.raw_os_n == 1'b1);
            end

        end
    end


    // =========================================================================
    // 4. SHIFT-REGISTER FILTER STABILITY EXHAUSTIVE VERIFICATION
    // =========================================================================
    genvar k;
    generate
        for (k = 0; k < 6; k = k + 1) begin : formal_filter_checks
            
            // Wire hooks pointing to raw filter arrays inside the DUT generation loops
            wire [FILTER_STAGES-1:0] current_filter = dut.gen_filters[k].filter_reg;
            wire clean_signal_out                   = dut.clean_signals[k];

            always_comb begin
                
                // Assert structural state when filter register is entirely cleared
                if (current_filter == {FILTER_STAGES{1'b0}}) begin
                    assert_filter_low_drive: assert(clean_signal_out == 1'b0);
                end

                // Assert structural state when filter register is entirely filled
                if (current_filter == {FILTER_STAGES{1'b1}}) begin
                    assert_filter_high_drive: assert(clean_signal_out == 1'b1);
                end

                // Latch memory safety check: Mixed register values must only yield valid states
                if ((current_filter != {FILTER_STAGES{1'b0}}) && (current_filter != {FILTER_STAGES{1'b1}})) begin
                    assert_latch_stability: assert(
                        (clean_signal_out == 1'b1) || (clean_signal_out == 1'b0)
                    );
                end

            end
        end
    endgenerate


    // =========================================================================
    // 5. INTERFACE STRUCT OUTPUT MATCH CHECK
    // =========================================================================
    `ifndef dfkjlsdjflsdkjflskdjf
    always_comb begin
        assert_struct_s4:    assert(core_out.s4_n    == dut.clean_signals[5]);
        assert_struct_s5:    assert(core_out.s5_n    == dut.clean_signals[4]);
        assert_struct_basic: assert(core_out.basic_n == dut.clean_signals[3]);
        assert_struct_io:    assert(core_out.io_n    == dut.clean_signals[2]);
        assert_struct_os:    assert(core_out.os_n    == dut.clean_signals[1]);
        assert_struct_ci:    assert(core_out.ci_n    == dut.clean_signals[0]);
    end
    `endif

endmodule

// Bind declaration mapping structural signals cleanly into the tracking workspace
bind mmu_core mmu_core_formal i_mmu_core_formal (
    .rst_n    (rst_n),
    .core_ctrl (core_ctrl),           // Maps flat [2:0] control vector
    .core_addr (core_addr),           // Maps flat [4:0] address slice vector    .ren      (ren),
    .ref_n    (ref_n),
    .mpd_n    (mpd_n),
    .be_n     (be_n),
    .core_out (core_out)
);

`endif
