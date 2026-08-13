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
 
`ifndef TT_UM_C061618G2_FORMAL_SV
`define TT_UM_C061618G2_FORMAL_SV

`default_nettype none

module tt_um_c061618g2_formal (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high)
    input  wire       ena,      // Core clock enable string
    input  wire       clk,      // System clock
    input  wire       rst_n     // Active-low asynchronous reset
);

    // ----------------------------------------------------------------
    // 1. Internal Signal Declarations & Clock/Reset Logic
    // ----------------------------------------------------------------
    wire rst = !rst_n;

    // ----------------------------------------------------------------
    // 2. Hardware Design Under Test (DUT) Instantiation
    // ----------------------------------------------------------------
    // Standard top-level instantiation for standalone formal analysis
    tt_um_c061618g2 dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // ----------------------------------------------------------------
    // 3. Formal Verification Assertions Engine (SBY Compatible)
    // ----------------------------------------------------------------
    `ifdef FORMAL
    
    // Step Monitor: Tracks if the simulation loop has advanced past the first cycle
    reg f_past_valid = 1'b0;
    always @(posedge clk) begin
        f_past_valid <= 1'b1;
    end

    // Local wire aliases matching the physical structural pinning matrices
    wire [4:0] addr            = ui_in[4:0];
    wire       map_n           = ui_in[5];
    wire       rd4             = ui_in[6];
    wire       rd5             = ui_in[7];

    wire       ren             = uio_in[0];
    wire       ref_n           = uio_in[1];
    wire       mpd_n           = uio_in[2];
    wire       be_n            = uio_in[3];
    wire       flg_n           = uio_in[4];
    wire       loop_in         = uio_in[6];

    // Master safety cutoff definition matching production RTL
    wire system_disabled = (flg_n == 1'b0) || (loop_in == 1'b0);

    // ----------------------------------------------------------------
    // Global Subsystem Assumptions & Invariants
    // ----------------------------------------------------------------
    always @(*) begin
        // Assume clock enable stays active during formal sequences
        assume(ena == 1'b1);
        
        // Pin Invariant Check: Direction control gates are hardcoded for Pmod 2 configurations
        assert_uio_direction: assert(uio_oe == 8'b00100000);
    end

    // ----------------------------------------------------------------
    // Procedural Immediate Assertions & Assumptions
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        
        // Target Reset Behavior Checking
        if (rst) begin
            assert_uo_reset:  assert(uo_out == 8'b00000000);
            assert_uio_reset: assert(uio_out == 8'b00000000);
        end
        
        // Functional Clocked Safety Verification
        if (f_past_valid && !rst) begin
            
            // --- A. Master System Override Verification ---
            if (system_disabled) begin
                // When system is disabled, all active-low selects must be driven high (1)
                assert_override_inactive: assert(uo_out[6:0] == 7'b1111111);
            end 
            else begin
                // --- B. Strict Memory Decoding Pass Windows ---
                
                // 1. Strict OS Kernel ROM Decoding Bounds ($E000 - $FFFF)
                if (map_n && ren && (addr >= 5'h1C) && (addr <= 5'h1F)) begin
                    assert_os_enabled:   assert(uo_out[2] == 1'b0); // os_n pulls low
                    assert_basic_masked: assert(uo_out[1] == 1'b1); // basic_n stays high
                end
                
                // 2. Strict BASIC Interpreter ROM Decoding Bounds ($A000 - $BFFF)
                if (map_n && be_n && (addr >= 5'h14) && (addr <= 5'h17)) begin
                    assert_basic_enabled: assert(uo_out[1] == 1'b0); // basic_n pulls low
                    assert_os_masked:    assert(uo_out[2] == 1'b1); // os_n stays high
                end
                
                // 3. Mutual Exclusion Sanity Verification at Pin Layer
                assert_pin_exclusivity: assert(!(uo_out[2] == 1'b0 && uo_out[1] == 1'b0));
            end
        end
    end

    // ----------------------------------------------------------------
    // Coverage Validation Points
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (f_past_valid && !rst && !system_disabled) begin
            // Verify reachability of a clean OS selection state
            cover_os_active:    cover(uo_out[2] == 1'b0 && uo_out[1] == 1'b1);
            
            // Verify reachability of a clean BASIC selection state
            cover_basic_active: cover(uo_out[1] == 1'b0 && uo_out[2] == 1'b1);
        end
    end

    `endif

endmodule

`endif
