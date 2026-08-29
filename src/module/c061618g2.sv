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

`ifndef C061618G2_SV
`define C061618G2_SV
`default_nettype none

`include "src/core/mmu_core.sv"

module c061618g2 (
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire        clk,      // Part of the strict wrapper standard!
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire        rst_n,    // Part of the strict wrapper standard!
    input  wire  [7:0] ui_in,    // Dedicated hardware inputs
    output logic [7:0] uo_out,   // Dedicated hardware outputs
    input  wire  [7:0] uio_in,   // Bidirectional bus input network
    output logic [7:0] uio_out,  // Bidirectional bus output network
    output logic [7:0] uio_oe,   // Safe output enablement bus mapping
    input  wire        ena       // Tiny Tapeout macro environment block enable signal
);
    /* verilator lint_off UNUSEDSIGNAL */
    // ---------------------------------------------------------------------
    // HAZARD-FREE OBSERVATION NETS
    // Changing 'bit' to 'wire' converts these from active simulation 
    // state drivers into safe, passive observation nets, completely
    // unlocking the control bus ports!
    // ---------------------------------------------------------------------
    wire unused_p2_b7 = uio_in[7]; 
    wire uio5_pad     = uio_in[5]; 
    wire TESTMODE_n   = uio_in[4]; 
    /* verilator lint_on UNUSEDSIGNAL */

    // =========================================================================
    // 3. HARDWARE BUS CONCATENATION
    // =========================================================================
    wire [12:0] functional_unfiltered;    
    
    assign functional_unfiltered = {
        uio_in[6],     // Bit 12 (MSB) -> FLG_IN_n
        uio_in[3:0],   // Bits 11:8    -> be_n, mpd_n, ref_n, ren
        ui_in[7:0]     // Bits 7:0     -> rd5, rd4, map_n, A15, A14, A13, A12, A11 (LSB)
    };

    // =========================================================================
    // 4. CLOCKLESS ASYNCHRONOUS GLITCH FILTER MATRIX
    // =========================================================================
    wire [12:0] filtered;
    
    async_glitch_filter_bank #(
        .WIDTH(13),
        .STAGES(4)
    ) u_mmu_filter_bank (
        .rst_n    (rst_n), 
        .async_in (functional_unfiltered),
        .async_out(filtered)
    );

    // =========================================================================
    // 5. UNIDIRECTIONAL DECOUPLING LAYER
    // =========================================================================
    wire clean_ren;
    wire clean_ref_n;
    wire clean_mpd_n;
    wire clean_be_n;

    assign clean_ren   = filtered[8];  
    assign clean_ref_n = filtered[9];  
    assign clean_mpd_n = filtered[10]; 
    assign clean_be_n  = filtered[11]; 
    
    pmod3_outputs_t core_signals;

    mmu_core core_inst (
        .rst_n     (rst_n),
        .core_ctrl (filtered[7:5]), 
        .core_addr (filtered[4:0]), 
        .ren       (clean_ren),   
        .ref_n     (clean_ref_n), 
        .mpd_n     (clean_mpd_n), 
        .be_n      (clean_be_n),  
        .core_out  (core_signals)
    );

    // =========================================================================
    // BUS TRISTATE SAFETY OVERRIDE
    // =========================================================================
    assign uio_oe = (rst_n && ena) ? 8'b00100000 : 8'b00000000; 

    // =========================================================================
    // CLEAN SILICON PROTECTION MATRIX
    // =========================================================================
    wire FLG_IN_n_top     = filtered[12];
    wire system_disabled  = (!FLG_IN_n_top) || (!ena) || (!rst_n);
    wire FLG_n            = system_disabled ? 1'b0 : 1'b1;
    wire a11_top          = filtered[0]; 

    /* verilator lint_off UNUSED */
    wire unused_p3_b7 = core_signals.unused_p3_b7;
    wire FLG_n_p3     = core_signals.FLG_n;
    /* verilator lint_on UNUSED */

    // =========================================================================
    // 6. PHYSICAL ROUTING MATRIX (HAZARD-FREE ATOMIC BUS ROUTING)
    // =========================================================================
    assign uio_out = system_disabled ? 8'b00000000 : {2'b00, a11_top, 5'b00000};

    // -------------------------------------------------------------------------
    // HAZARD-FREE SIMULATION BUS HARNESS
    // Packs your structural pmod3 outputs directly into the flat bus vector
    // matching the exact indices declared in your pmod3_outputs_t struct.
    // -------------------------------------------------------------------------
    logic [7:0] raw_uo_out;
    
    always_comb begin
        if (system_disabled) begin
            // -----------------------------------------------------------------
            // HARDWARE CONSTANT MATRIX:
            // Bit 7: 1'b0 (Static Ground Tie-off)
            // Bit 6: 1'b0 (FLG_n -> Clamped low to show inactive/disabled state)
            // Bits 5:0: 6'b111111 (All memory select lines forced high/inactive)
            // Combined Vector Word: 8'b00111111 ($3F)
            // -----------------------------------------------------------------
            raw_uo_out = 8'b00111111; 
        end else begin
            raw_uo_out[0] = core_signals.s5_n;     // Bit 0
            raw_uo_out[1] = core_signals.basic_n;  // Bit 1
            raw_uo_out[2] = core_signals.os_n;     // Bit 2
            raw_uo_out[3] = core_signals.ci_n;     // Bit 3
            raw_uo_out[4] = core_signals.io_n;     // Bit 4
            raw_uo_out[5] = core_signals.s4_n;     // Bit 5
            raw_uo_out[6] = FLG_n;                 // Bit 6
            raw_uo_out[7] = 1'b0;                  // Bit 7 (Static Ground)
        end
    end

    // Unified assignment guarantees no delta-cycle simulation skew
    assign uo_out = raw_uo_out;

endmodule

`default_nettype wire
`endif