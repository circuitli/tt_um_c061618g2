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
    output wire [7:0] uio_oe,   // Direction control vector
    input  wire       ena,              // Core clock enable string
    input  wire       clk,              // Master system clock
    input  wire       rst_n,            // Asynchronous active-low reset
    input  wire       phase_clk,        // Internal evaluation clock from DUT mux
    input  wire       sys_clk           // Internal gated/synchronized clock domain
);

    // ----------------------------------------------------------------
    // 1. Internal Signal Declarations & Clock/Reset Logic
    // ----------------------------------------------------------------
    wire rst = !rst_n;

    // ----------------------------------------------------------------
    // 2. Hardware Design Under Test (DUT) Instantiation
    // ----------------------------------------------------------------
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
    wire       TESTMODE_n      = uio_in[4];
    wire       flg_n           = uio_in[6];

    // Master safety cutoff definition matching production RTL
    wire system_disabled = (flg_n == 1'b0) || (ena == 1'b0) || (rst_n == 1'b0);

    // 16-Bit Descriptive Memory Address Space Constants
    parameter [15:0] CART_S4_START      = 16'h8000;
    parameter [15:0] CART_S4_END        = 16'h9FFF;
    parameter [15:0] CART_S5_START      = 16'hA000;
    parameter [15:0] CART_S5_END        = 16'hBFFF;
    parameter [15:0] HARDWARE_IO_START  = 16'hD000;
    parameter [15:0] HARDWARE_IO_END    = 16'hD7FF;
    parameter [15:0] LOWER_OS_ROM_START = 16'hC000;
    parameter [15:0] LOWER_OS_ROM_END   = 16'hCFFF;
    parameter [15:0] UPPER_OS_ROM_START = 16'hE000;
    parameter [15:0] UPPER_OS_ROM_END   = 16'hFFFF;

    // ----------------------------------------------------------------
    // Global Subsystem Assumptions & Invariants
    // ----------------------------------------------------------------
    always @(*) begin
        // Pin Invariant Check: Direction control gates are hardcoded for Pmod 2 configurations
        assert_uio_direction: assert(uio_oe == 8'b00100000);

        assert_LOOP_OUT: assert(uo_out[6] == 1);

        if (!TESTMODE_n) begin
            // Safe state validation (active only after reset drops to prevent cycle 0 conflicts)
            if (rst) begin
                assert_dft_outputs_safe: assert (uo_out == 8'b01111111);
            end
        end
    end

    always @(posedge clk) begin
        if (f_past_valid && !rst) begin
            // Verifies the structural path on the active sampling edge
            if (!TESTMODE_n) begin
                assert_dft_clock_and_enable_isolation: assert (phase_clk == 1'b1);
            end
        end
    end

    // ----------------------------------------------------------------
    // Procedural Immediate Assertions & Assumptions
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        
        // Target Reset Behavior Checking
        if (rst) begin
            assert_uo_reset:  assert (uo_out == 8'b01111111);
            assert_uio_reset: assert(uio_out == 8'b00100000);
        end
        
        // Functional Clocked Safety Verification
        if (f_past_valid && !rst && !system_disabled) begin

            // Clock verification rules (Always checked when system is active)
            if (!TESTMODE_n) begin
                assert_dft_clock_test: assert(phase_clk == clk);
            end
            if (TESTMODE_n) begin
                assert_dft_clock_norm: assert(phase_clk == sys_clk);
            end
            
            // --- MEMORY DECODING CORES (Only valid when NOT in TESTMODE) ---
            if (TESTMODE_n) begin
            
                // Passthrough Check: Verify that TRIGGER_OUT (uio_out[5]) directly tracks address line A11 (ui_in[0])
                assert_trigger_out_passthrough: assert(uio_out[5] == ui_in[0]);
                
                // --- A. Strict Memory Decoding Pass Windows ---
                
                // 1. Split-Zone OS Kernel ROM Decoding Bounds ($C000-$CFFF and $E000-$FFFF)
                if (map_n && ren && (((addr >= LOWER_OS_ROM_START[15:11]) && (addr <= LOWER_OS_ROM_END[15:11])) || 
                                    ((addr >= UPPER_OS_ROM_START[15:11]) && (addr <= UPPER_OS_ROM_END[15:11])))) begin
                    assert_os_enabled:   assert(uo_out[2] == 1'b0); // os_n pulls low
                    assert_basic_masked: assert(uo_out[1] == 1'b1); // basic_n stays high
                end
                
                // 2. Strict BASIC Interpreter ROM Decoding Bounds ($A000 - $BFFF) with Left Cartridge Interlocking
                if (map_n && be_n && !rd5 && (addr >= CART_S5_START[15:11]) && (addr <= CART_S5_END[15:11])) begin
                    assert_basic_enabled: assert(uo_out[1] == 1'b0); // basic_n pulls low
                    assert_os_masked:    assert(uo_out[2] == 1'b1); // os_n stays high
                end

                // 3. Strict Hardware I/O Select Decoding Bounds ($D000 - $D7FF)
                if (map_n && ren && (addr == HARDWARE_IO_START[15:11])) begin
                    assert_io_enabled:   assert(uo_out[4] == 1'b0); // io_n pulls low
                end

                // 4. Expansion Cartridge Slot S4 Select Bounds ($8000 - $9FFF)
                if (map_n && rd4 && (addr >= CART_S4_START[15:11]) && (addr <= CART_S4_END[15:11])) begin
                    assert_s4_enabled:   assert(uo_out[5] == 1'b0); // s4_n pulls low
                end

                // 5. Expansion Cartridge Slot S5 Select Bounds ($A000 - $BFFF)
                if (map_n && rd5 && (addr >= CART_S5_START[15:11]) && (addr <= CART_S5_END[15:11])) begin
                    assert_s5_enabled:   assert(uo_out[0] == 1'b0); // s5_n pulls low
                end

                // 6. CAS Inhibit/Refresh Dynamic RAM Select Bounds
                if (map_n && ref_n && (addr == HARDWARE_IO_START[15:11])) begin
                    assert_ci_enabled:   assert(uo_out[3] == 1'b0); // ci_n pulls low
                end
                
                // --- B. Expanded Pairwise Mutual Exclusion Matrix ---
                assert_mut_os_basic: assert(!(uo_out[2] == 1'b0 && uo_out[1] == 1'b0));
                assert_mut_os_io:    assert(!(uo_out[2] == 1'b0 && uo_out[4] == 1'b0));
                assert_mut_os_s4:    assert(!(uo_out[2] == 1'b0 && uo_out[5] == 1'b0));
                assert_mut_os_s5:    assert(!(uo_out[2] == 1'b0 && uo_out[0] == 1'b0));
                
                assert_mut_basic_io: assert(!(uo_out[1] == 1'b0 && uo_out[4] == 1'b0));
                assert_mut_basic_s4: assert(!(uo_out[1] == 1'b0 && uo_out[5] == 1'b0));
                assert_mut_basic_s5: assert(!(uo_out[1] == 1'b0 && uo_out[0] == 1'b0));
                
                assert_mut_io_s4:    assert(!(uo_out[4] == 1'b0 && uo_out[5] == 1'b0));
                assert_mut_io_s5:    assert(!(uo_out[4] == 1'b0 && uo_out[0] == 1'b0));
                
                assert_mut_s4_s5:    assert(!(uo_out[5] == 1'b0 && uo_out[0] == 1'b0));
            end
        end
    end

    // ----------------------------------------------------------------
    // 4. Coverage Validation Points
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (f_past_valid && !rst && !system_disabled && TESTMODE_n) begin
            cover_os_active:    cover(uo_out[2] == 1'b0);
            cover_basic_active: cover(uo_out[1] == 1'b0);
            cover_io_active:    cover(uo_out[4] == 1'b0);
            cover_s4_active:    cover(uo_out[5] == 1'b0);
            cover_s5_active:    cover(uo_out[0] == 1'b0);
            cover_ci_active:    cover(uo_out[3] == 1'b0);
        end
    end

    `endif

endmodule

// =========================================================================
// BIND DIRECTIVE: Inject properties cleanly into production RTL target
// =========================================================================
bind tt_um_c061618g2 tt_um_c061618g2_formal i_tt_um_c061618g2_formal (
    .ui_in     (ui_in),
    .uo_out    (uo_out),
    .uio_in    (uio_in),
    .ena       (ena),
    .clk       (clk),
    .rst_n     (rst_n),
    .phase_clk (phase_clk),
    .sys_clk   (sys_clk)
);
`endif