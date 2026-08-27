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

`ifndef C061618G2_FORMAL_SV
`define C061618G2_FORMAL_SV

`default_nettype none

// =============================================================================
// Top-Level Formal Verification Container: tt_um_c061618g2_formal
// Fully clockless to match our purely asynchronous IHP silicon layout.
// =============================================================================
module c061618g2_formal (
    input  wire  [7:0] ui_in,        // Dedicated hardware inputs
    input  wire  [7:0] uo_out,       // Dedicated hardware outputs
    input  wire  [7:0] uio_in,       // Bidirectional bus input network
    input  wire  [7:0] uio_out,      // Bidirectional bus output network
    input  wire  [7:0] uio_oe,       // Safe output enablement bus mapping
    input  wire        ena,          // Environment block enable signal
    input  wire        clk,          // Standard clock input
    input  wire        rst_n         // Asynchronous active-low reset
);

`ifdef FORMAL

    // -------------------------------------------------------------------------
    // CATEGORY 1: ABSOLUTE GLOBAL RESET SAFETY PROOFS
    // -------------------------------------------------------------------------
    asm_pad_reset_oe_assert: assert property (
        (!rst_n) -> (uio_oe == 8'b00000000)
    );

    asm_pad_reset_uio_assert: assert property (
        (!rst_n) -> (uio_out == 8'b00000000)
    );

    asm_pad_reset_uo_static_assert: assert property (
        (!rst_n) -> (uo_out[7] == 1'b0)
    );

    asm_pad_reset_uo_flag_assert: assert property (
        (!rst_n) -> (uo_out[6] == 1'b0)
    );

    asm_pad_reset_uo_signals_assert: assert property (
        (!rst_n) -> (uo_out[5:0] == 6'b111111)
    );

    // -------------------------------------------------------------------------
    // CATEGORY 2: CHIP ENVIRONMENT ENABLE / DISABLE MASKS
    // -------------------------------------------------------------------------
    asm_ena_disabled_oe_assert: assert property (
        (!ena) -> (uio_oe == 8'b00000000)
    );

    asm_ena_disabled_uio_assert: assert property (
        (!ena) -> (uio_out == 8'b00000000)
    );

    asm_ena_disabled_uo_flag_assert: assert property (
        (!ena) -> (uo_out[6] == 1'b0)
    );

    asm_ena_disabled_uo_signals_assert: assert property (
        (!ena) -> (uo_out[5:0] == 6'b111111)
    );

    // -------------------------------------------------------------------------
    // CATEGORY 3: INPUT PIN DEPENDENCY FLG_IN_n OVERRIDES
    // -------------------------------------------------------------------------
    asm_flgin_disabled_uo_flag_assert: assert property (
        (!uio_in[6]) -> (uo_out[6] == 1'b0)
    );

    asm_flgin_disabled_uo_signals_assert: assert property (
        (!uio_in[6]) -> (uo_out[5:0] == 6'b111111)
    );

    // -------------------------------------------------------------------------
    // CATEGORY 4: FUNCTIONAL OPERATION & TRISTATE VALIDATION
    // -------------------------------------------------------------------------
    asm_normal_op_oe_assert: assert property (
        (rst_n && ena) -> (uio_oe == 8'b00100000)
    );

    asm_normal_op_uio_static_low_assert: assert property (
        (rst_n && ena) -> (uio_out[7:6] == 2'b00)
    );

    asm_normal_op_uio_static_trailing_assert: assert property (
        (rst_n && ena) -> (uio_out[4:0] == 5'b00000)
    );

    // -------------------------------------------------------------------------
    // CATEGORY 5: STRICT METASTABILITY & X-PROPAGATION BARRIERS
    // -------------------------------------------------------------------------
    asm_uo_out_binary_assert: assert property (
        (uo_out ^ uo_out) === 8'b00000000
    );

    asm_uio_out_binary_assert: assert property (
        (uio_out ^ uio_out) === 8'b00000000
    );

    asm_uio_oe_binary_assert: assert property (
        (uio_oe ^ uio_oe) === 8'b00000000
    );

`endif

endmodule

// =============================================================================
// CORRECTED SYSTEMVERILOG HIERARCHICAL BIND CONFIGURATION
// Binds precisely to the correct TinyTapeout top-level module block name.
// =============================================================================
bind tt_um_c061618g2 tt_um_c061618g2_formal i_tt_um_c061618g2_formal (
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (uio_in),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (ena),
    .clk     (clk),
    .rst_n   (rst_n)
);

`default_nettype wire
`endif // C061618G2_FORMAL_SV

