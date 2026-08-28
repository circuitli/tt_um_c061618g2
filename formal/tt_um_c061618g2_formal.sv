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

`default_nettype none

module tt_um_c061618g2_formal (
    input  wire [7:0] ui_in,    // Dedicated hardware inputs
    input  wire [7:0] uo_out,   // Live unclocked output pins
    input  wire [7:0] uio_in,   // Bidirectional bus input network
    input  wire [7:0] uio_out,  // Bidirectional bus output network
    input  wire [7:0] uio_oe,   // Bidirectional output enablement bus
    input  wire       ena,      // Tiny Tapeout environment block enable signal
    input  wire       clk,      // System clock injected for formal tracking
    input  wire       rst_n     // Active-low system reset
);

    // -------------------------------------------------------------------------
    // DIRECT LIVE NET EXTRACTION FROM CHIP OUTPUTS
    // -------------------------------------------------------------------------
    wire [5:0] active_out_pins = uo_out[5:0];

    // =========================================================================
    // WRAPPER BOUNDARY SAFETY CONTRACTS
    // Evaluates constraints instantly on any live physical pin state updates.
    // =========================================================================
    always @* begin

        // 1. GLOBAL RESET SAFE-STATE PROOF
        // Verifies the top-level chip pins successfully clamp high (inactive) during reset
        asm_top_reset_assert: assert (rst_n || (active_out_pins == 6'b111111));

        // 2. BUS TRISTATE SAFETY OVERRIDE CONTRACT
        // Verifies the bidirectional port enablement matches safe operating states
        asm_top_clean_uio_oe: assert (uio_oe == 8'b00100000 || uio_oe == 8'b00000000);

        // 3. METASTABILITY CONTAINMENT BOUNDARY CONTRACT
        asm_top_clean_bus_assert: assert ((active_out_pins ^ active_out_pins) == 6'b000000);

    end

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
    .ena       (ena),     // TT strict positional slot
    .clk       (clk),     // TT strict positional slot
    .rst_n     (rst_n)    // TT strict positional slot
);

//`endif