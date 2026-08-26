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

// ==============================================================================
// SECTION: TOP-LEVEL HARDWARE WRAPPER CONSTRAINTS
// ==============================================================================
`default_nettype none

`include "src/module/c061618g2.sv"

module tt_um_c061618g2 (
    input  [7:0] ui_in,    // Dedicated hardware inputs
    output [7:0] uo_out,   // Dedicated hardware outputs
    input  [7:0] uio_in,   // Bidirectional bus input network
    output [7:0] uio_out,  // Bidirectional bus output network
    output wire [7:0] uio_oe,   // <-- MUST BE DECLARED AS AN OUTPUT PORT WIRE HERE! [2]
    input  [0:0] ena,      // Leave this here! The compiler requires it.
    input  [0:0] clk,      // Part of the strict wrapper standard!
    input  [0:0] rst_n     // Part of the strict wrapper standard!
);

/*
    // INJECT THE PHYSICAL BOUNDING BOX DIRECTLY HERE:
    // This forces the backend to evaluate the pure layout strings natively inside OpenROAD
`ifdef SYNTHESIS
    // OpenROAD native region execution parameters
    // Syntax: create_region_fence <name> <X1> <Y1> <X2> <Y2>
    initial begin
        $display("openroad_command: create_region_fence u_box 10.0 10.0 55.36 25.12");
        $display("openroad_command: assign_region u_box [get_cells -hierarchical -filter \"name =~ *u_c061618g2*\"]");
    end
`endif
*/

    // =========================================================================
    // THE TOP-LEVEL HARDWARE MASK BOUNDARY (PRESERVES TRUE REBOOT POLARITIES)
    // Running case-equality selections right here breaks the tristate graph
    // while shielding the design from uninitialized simulation leaks.
    // =========================================================================
    wire [7:0] safe_top_ui;
    wire [7:0] safe_top_uio;

    always_comb begin
        // --- ui_in Channel Masking ---
        safe_top_ui[0] = (ui_in[0] === 1'bx || ui_in[0] === 1'bz) ? 1'b1 : (ui_in[0] & 1'b1); // A11
        safe_top_ui[1] = (ui_in[1] === 1'bx || ui_in[1] === 1'bz) ? 1'b1 : (ui_in[1] & 1'b1); // A12
        safe_top_ui[2] = (ui_in[2] === 1'bx || ui_in[2] === 1'bz) ? 1'b1 : (ui_in[2] & 1'b1); // A13
        safe_top_ui[3] = (ui_in[3] === 1'bx || ui_in[3] === 1'bz) ? 1'b1 : (ui_in[3] & 1'b1); // A14
        safe_top_ui[4] = (ui_in[4] === 1'bx || ui_in[4] === 1'bz) ? 1'b1 : (ui_in[4] & 1'b1); // A15
        safe_top_ui[5] = (ui_in[5] === 1'bx || ui_in[5] === 1'bz) ? 1'b1 : (ui_in[5] & 1'b1); // map_n
        safe_top_ui[6] = (ui_in[6] === 1'bx || ui_in[6] === 1'bz) ? 1'b0 : (ui_in[6] & 1'b1); // rd4 -> 0
        safe_top_ui[7] = (ui_in[7] === 1'bx || ui_in[7] === 1'bz) ? 1'b0 : (ui_in[7] & 1'b1); // rd5 -> 0

        // --- uio_in Channel Masking ---
        safe_top_uio[0] = (uio_in[0] === 1'bx || uio_in[0] === 1'bz) ? 1'b0 : (uio_in[0] & 1'b1); // ren -> 0
        safe_top_uio[1] = (uio_in[1] === 1'bx || uio_in[1] === 1'bz) ? 1'b1 : (uio_in[1] & 1'b1); // ref_n 
        safe_top_uio[2] = (uio_in[2] === 1'bx || uio_in[2] === 1'bz) ? 1'b1 : (uio_in[2] & 1'b1); // mpd_n 
        safe_top_uio[3] = (uio_in[3] === 1'bx || uio_in[3] === 1'bz) ? 1'b1 : (uio_in[3] & 1'b1); // be_n  
        safe_top_uio[6] = (uio_in[6] === 1'bx || uio_in[6] === 1'bz) ? 1'b1 : (uio_in[6] & 1'b1); // FLG_IN_n

        // Route unreferenced bits using safe identity logic to preserve graph isolation
        safe_top_uio[4] = (uio_in[4] === 1'bx || uio_in[4] === 1'bz) ? 1'b1 : (uio_in[4] & 1'b1);
        safe_top_uio[5] = (uio_in[5] === 1'bx || uio_in[5] === 1'bz) ? 1'b1 : (uio_in[5] & 1'b1);
        safe_top_uio[7] = (uio_in[7] === 1'bx || uio_in[7] === 1'bz) ? 1'b1 : (uio_in[7] & 1'b1);
    end

    // =========================================================================
    // CORE INSTANTIATION (CONNECTED TO SECURED DATA STREAMS)
    // =========================================================================
    (* keep_hierarchy = 1 *)   
    c061618g2 u_c061618g2 (
        .ui_in    (safe_top_ui),  // Clean, 2-state shielded input bus
        .uo_out   (uo_out),       
        .uio_in   (safe_top_uio), // Clean, 2-state shielded bidirectional bus
        .uio_out  (uio_out),  
        .uio_oe   (uio_oe),  
        .ena      (ena),      
        .clk      (clk),     
        .rst_n    (rst_n)    
    ); 

endmodule

`default_nettype wire
