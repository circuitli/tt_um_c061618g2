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

`include "src/module/c061618g2_input_shield.sv"
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
    logic [7:0] safe_ui;
    logic [7:0] safe_uio;
    
    /*
    // =========================================================================
    // CUSTOM ASYNCHRONOUS COUPLER INTERFACE BOUNDARY
    // Connects the raw implicit-wire top ports to the variable logic trackers.
    // =========================================================================
    c061618g2_input_shield u_c061618g2_input_shield (
        .ui_in   (ui_in),          // Connected directly to raw top-level input vector
        .uio_in  (uio_in),         // Connected directly to raw top-level bidirectional vector
        .safe_ui  (clean_ui),   // Outputs clean, type-decoupled, safe 2-state logic lines
        .safe_uio (clean_uio)   // Outputs clean, type-decoupled, safe 2-state logic lines
    );
    */

    // =========================================================================
    // PROCEDURAL ISOLATION BOUNDARY
    // Placing these bit-by-bit inside an always_comb block forces Verilator
    // to drop the structural wire tracking graph, rendering them as clean variables.
    // =========================================================================
    /*
    always_comb begin
        // --- ui_in Channel Masking (Address Matrix & Map Controls) ---
        // Address lines A11-A15 default high (1'b1) via motherboard pull-ups
        safe_ui[0] = (ui_in[0] === 1'bx || ui_in[0] === 1'bz) ? 1'b1 : (ui_in[0] == 1'b1); // A11
        safe_ui[1] = (ui_in[1] === 1'bx || ui_in[1] === 1'bz) ? 1'b1 : (ui_in[1] == 1'b1); // A12
        safe_ui[2] = (ui_in[2] === 1'bx || ui_in[2] === 1'bz) ? 1'b1 : (ui_in[2] == 1'b1); // A13
        safe_ui[3] = (ui_in[3] === 1'bx || ui_in[3] === 1'bz) ? 1'b1 : (ui_in[3] == 1'b1); // A14
        safe_ui[4] = (ui_in[4] === 1'bx || ui_in[4] === 1'bz) ? 1'b1 : (ui_in[4] == 1'b1); // A15
    
        // Active-low MMU map control defaults high (1'b1) to remain unasserted/idle
        safe_ui[5] = (ui_in[5] === 1'bx || ui_in[5] === 1'bz) ? 1'b1 : (ui_in[5] == 1'b1); // map_n
    
        // Active-high cartridge lines default low (1'b0) via motherboard pull-downs
        safe_ui[6] = (ui_in[6] === 1'bx || ui_in[6] === 1'bz) ? 1'b0 : (ui_in[6] == 1'b1); // rd4
        safe_ui[7] = (ui_in[7] === 1'bx || ui_in[7] === 1'bz) ? 1'b0 : (ui_in[7] == 1'b1); // rd5


        // --- uio_in Channel Masking (Control Channels) ---
        // ren is active-high, so its safe boot baseline defaults low (1'b0)
        safe_uio[0] = (uio_in[0] === 1'bx || uio_in[0] === 1'bz) ? 1'b0 : (uio_in[0] == 1'b1); // ren
    
        // Active-low control channels default high (1'b1) to remain unasserted/idle
        safe_uio[1] = (uio_in[1] === 1'bx || uio_in[1] === 1'bz) ? 1'b1 : (uio_in[1] == 1'b1); // ref_n 
        safe_uio[2] = (uio_in[2] === 1'bx || uio_in[2] === 1'bz) ? 1'b1 : (uio_in[2] == 1'b1); // mpd_n 
        safe_uio[3] = (uio_in[3] === 1'bx || uio_in[3] === 1'bz) ? 1'b1 : (uio_in[3] == 1'b1); // be_n  
        safe_uio[6] = (uio_in[6] === 1'bx || uio_in[6] === 1'bz) ? 1'b1 : (uio_in[6] == 1'b1); // FLG_IN_n


        // --- Unreferenced Padding Channels (Strips UNUSEDSIGNAL warnings completely) ---
        safe_uio[4] = (uio_in[4] == 1'b1);
        safe_uio[5] = (uio_in[5] == 1'b1);
        safe_uio[7] = (uio_in[7] == 1'b1);
    end
    */
    /*
    always_comb begin
        if (!rst_n) begin
            // --- HARDWARE RESET STATE (Forces safe pull-up/down values) ---
            safe_ui[4:0] = 5'b11111; // Default address lines high
            safe_ui[5]   = 1'b1;     // Default map_n high (idle)
            safe_ui[7:6] = 2'b00;    // Default rd4/rd5 low
            
            safe_uio     = 8'b11111110; // Sets control lines to default idle states
        end else begin
            // --- ACTIVE FUNCTIONAL STATE ---
            // Direct pass-through. Transistors handle standard high/low logic.
            safe_ui  = ui_in;
            safe_uio = uio_in;
        end
    end
    */

    // =========================================================================
    // SYNTHESIZABLE CONTINUOUS HARDWARE INPUT SHIELD
    // Uses structural gate logic to force clean states when 'ena' is low.
    // When 'ena' goes high, it acts as a perfect, non-blocking wire path.
    // =========================================================================
    /*
    always_comb begin
        // --- Synthesizable Pull-Up Shield (OR Gate forces 1'b1 when ena=0) ---
        safe_ui[0] = ui_in[0] | ~ena; // A11 Address line
        safe_ui[1] = ui_in[1] | ~ena; // A12 Address line
        safe_ui[2] = ui_in[2] | ~ena; // A13 Address line
        safe_ui[3] = ui_in[3] | ~ena; // A14 Address line
        safe_ui[4] = ui_in[4] | ~ena; // A15 Address line
        safe_ui[5] = ui_in[5] | ~ena; // map_n control channel
    
        // --- Synthesizable Pull-Down Shield (AND Gate forces 1'b0 when ena=0) ---
        safe_ui[6] = ui_in[6] & ena;  // rd4 cartridge line
        safe_ui[7] = ui_in[7] & ena;  // rd5 cartridge line

        // --- uio_in Control Channel Clamping ---
        safe_uio[0] = uio_in[0] & ena;  // ren (Active-High defaults low)
        safe_uio[1] = uio_in[1] | ~ena; // ref_n (Active-Low defaults high)
        safe_uio[2] = uio_in[2] | ~ena; // mpd_n (Active-Low defaults high)
        safe_uio[3] = uio_in[3] | ~ena; // be_n  (Active-Low defaults high)
        safe_uio[6] = uio_in[6] | ~ena; // FLG_IN_n (Active-Low defaults high)

        // --- Unreferenced Padding Channels (Tied to safe 0 states) ---
        safe_uio[4] = 1'b0;
        safe_uio[5] = 1'b0;
        safe_uio[7] = 1'b0;
    end#
    */

    // =========================================================================
    // INTERMEDIATE FUNCTIONAL TRACKING WIRES
    // =========================================================================
    // Instantiate your packed struct as an internal variable to catch core logic
    //pmod3_outputs_t core_pmod3_out; 
    // 1. Declare a clean 8-bit intermediate wire vector
    wire [7:0] flat_core_uo;
    wire [7:0] core_uio_out;

    // =========================================================================
    // 3. CORE SUBMODULE INSTANTIATION
    // =========================================================================
    (* keep_hierarchy = 1 *)   
    c061618g2 u_c061618g2 (
        .ui_in    (safe_ui),   // Completely clean unidirectional data bus
        .uo_out   (flat_core_uo),       
        .uio_in   (safe_uio),  // Completely clean unidirectional control bus
        .uio_out  (core_uio_out),  
        .uio_oe   (uio_oe),  
        .ena      (ena),      
        .clk      (clk),     
        .rst_n    (rst_n)    
    ); 

    // =========================================================================
    // CORRECTED ACTIVE-LOW HARDWARE FIREWALL
    // If out_en is true, pass functional core values.
    // If out_en is false (reset/disabled/X), force safe idle lines (All 1s, Bit 7 = 0)
    // =========================================================================
    
    // Explicitly confirm both control pins are driven high to allow pass-through
    wire out_en = (ena == 1'b1) && (rst_n == 1'b1);

    // Safe Idle Configuration: 8'b01111111 (Bit 7 is 0, Bits 6-0 are 1)
    assign uo_out  = (out_en) ? 8'(core_pmod3_out) : 8'b01111111;
    
    // Keep bidirectional control buses safe during reset
    assign uio_out = (out_en) ? flat_core_uo       : 8'b00000000;


endmodule

`default_nettype wire
