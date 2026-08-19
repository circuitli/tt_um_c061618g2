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
 *
 
 
//`ifndef TT_UM_C061618G2_FORMAL_SV
//`define TT_UM_C061618G2_FORMAL_SV

/// ==============================================================================
// SECTION: TOP-LEVEL HARDWARE WRAPPER FORMAL PROPERTIES
// ==============================================================================
`default_nettype none

module tt_um_c061618g2_formal (
    input wire [7:0] ui_in,
    input wire [7:0] uo_out,
    input wire [7:0] uio_in,
    input wire [7:0] uio_out,
    input wire [7:0] uio_oe,
    input wire [0:0] ena,
    input wire [0:0] clk,
    input wire [0:0] rst_n
);

`ifdef FORMAL
    // --------------------------------------------------------------------------
    // 1. System Reset Assumption
    // --------------------------------------------------------------------------
    // Force the solver to boot with an active initial reset cycle
    f_boot_reset: assume property (!rst_n);

    // --------------------------------------------------------------------------
    // 2. Interface Protocol Assertions
    // --------------------------------------------------------------------------
    // When disabled, verify all output ports stay clamped to zero-drive
    a_disabled_outputs_inactive: assert property (
        @(posedge clk) disable iff (!rst_n)
        (!ena) |-> (uo_out == 8'b0 && uio_out == 8'b0 && uio_oe == 8'b0)
    );

    // --------------------------------------------------------------------------
    // 3. Atari Bus Contention Prevention Rules
    // --------------------------------------------------------------------------
    // Verify bidirectional out-enables map safely to valid Atari configurations
    a_uio_oe_safety: assert property (
        @(posedge clk) disable iff (!rst_n)
        ena |-> (uio_oe == 8'h00 || uio_oe == 8'hFF || uio_oe == 8'hF0 || uio_oe == 8'h0F)
    );

    // --------------------------------------------------------------------------
    // 4. Liveness Functional Covers
    // --------------------------------------------------------------------------
    // Ensure outputs can actively transition state during valid execution windows
    c_output_activity: cover property (
        @(posedge clk) disable iff (!rst_n)
        (ena && $rose(ui_in)) ##[1:5] $changed(uo_out)
    );

endmodule

// =========================================================================
// BIND DIRECTIVE: Inject properties cleanly into production RTL target
// =========================================================================
bind tt_um_c061618g2 tt_um_c061618g2_formal i_tt_um_c061618g2_formal (
    .ui_in     (ui_in),
    .uo_out    (uo_out),
    .uio_in    (uio_in),
    .uio_out   (uio_out),
    .uio_oe    (uio_oe),
    .ena       (ena),
    .clk       (clk),
    .rst_n     (rst_n)
);
//`endif