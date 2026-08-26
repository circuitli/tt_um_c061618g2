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
    // 1. PURE 2-STATE VARIABLE FIREWALL (BREAKS FORWARD PROPAGATION)
    // Declaring these as logic arrays and forcing a 2-state boolean reduction
    // clears Verilator's bidirectional look-ahead engine at the front door.
    // =========================================================================
    logic [7:0] clean_ui;
    logic [7:0] clean_uio;
    
    always_comb begin
        // Forcing a bitwise reduction (conditional bit extraction) shatters the graph
        for (int i = 0; i < 8; i = i + 1) begin
            clean_ui[i]  = (ui_in[i]  === 1'bx || ui_in[i]  === 1'bz) ? 1'b1 : (ui_in[i]  == 1'b1);
            clean_uio[i] = (uio_in[i] === 1'bx || uio_in[i] === 1'bz) ? 1'b1 : (uio_in[i] == 1'b1);
        end
        
        // Enforce your precise startup polarities explicitly on the 2-state logic variables
        if (rst_n === 1'b0) begin
            clean_uio[0] = 1'b0; // ren defaults to 0 (disabled)
            clean_ui[6]  = 1'b0; // rd4 defaults to 0 (pulled down)
            clean_ui[7]  = 1'b0; // rd5 defaults to 0 (pulled down)
        end
    end

    // =========================================================================
    // 3. CORE SUBMODULE INSTANTIATION
    // =========================================================================
    (* keep_hierarchy = 1 *)   
    c061618g2 u_c061618g2 (
        .ui_in    (clean_ui),   // Completely clean unidirectional data bus
        .uo_out   (uo_out),       
        .uio_in   (clean_uio),  // Completely clean unidirectional control bus
        .uio_out  (uio_out),  
        .uio_oe   (uio_oe),  
        .ena      (ena),      
        .clk      (clk),     
        .rst_n    (rst_n)    
    ); 

endmodule

`default_nettype wire
