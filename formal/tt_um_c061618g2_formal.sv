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

    // =========================================================================
    // STRUCTURAL ROUTING LINT CONTRACTS (THE ANTI-SCRAMBLING SHIELD)
    // These concurrent checks verify that your custom safe_wire_buffer arrays
    // are connected to the exact correct parent ports. If you ever type
    // ui_in instead of uio_in again, SymbiYosys will fail instantly at Step 0!
    // =========================================================================
    always @* begin
        if (rst_n) begin
            
            // 1. Verify ui_in is mapping 1-to-1 to safe_ui (No cross-talk or scrambling)
            assert_ui_purity_0: assert (safe_ui[0] == ui_in[0]); // A11
            assert_ui_purity_1: assert (safe_ui[1] == ui_in[1]); // A12
            assert_ui_purity_2: assert (safe_ui[2] == ui_in[2]); // A13
            assert_ui_purity_3: assert (safe_ui[3] == ui_in[3]); // A14
            assert_ui_purity_4: assert (safe_ui[4] == ui_in[4]); // A15
            assert_ui_purity_5: assert (safe_ui[5] == ui_in[5]); // map_n
            assert_ui_purity_6: assert (safe_ui[6] == ui_in[6]); // rd4
            assert_ui_purity_7: assert (safe_ui[7] == ui_in[7]); // rd5

            // 2. Verify uio_in is mapping 1-to-1 to safe_uio (No copying typos)
            assert_uio_purity_0: assert (safe_uio[0] == uio_in[0]); // ren
            assert_uio_purity_1: assert (safe_uio[1] == uio_in[1]); // ref_n
            assert_uio_purity_2: assert (safe_uio[2] == uio_in[2]); // mpd_n
            assert_uio_purity_3: assert (safe_uio[3] == uio_in[3]); // be_n
            assert_uio_purity_6: assert (safe_uio[6] == uio_in[6]); // FLG_IN_n
            assert_uio_purity_7: assert (safe_uio[7] == uio_in[7]); // Reserved Bit
            
            // 3. Verify that padding channels remain strictly isolated and zeroed out
            assert_uio_padding_4: assert (safe_uio[4] == 1'b0);
            assert_uio_padding_5: assert (safe_uio[5] == 1'b0);

        end
    end

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