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

`ifndef C061618G2_INPUT_SHHIELD_SV
`define C061618G2_INPUT_SHHIELD_SV
`default_nettype none

// =========================================================================
// TINY TAPEOUT ASYNCHRONOUS INPUT SHIELD & TYPE COMPATIBILITY COUPLER
// Inputs: Explicit variable 'logic' types to capture and snapshot signals.
// Outputs: Explicit structural 'wire' types to unlink the tracking graph.
// =========================================================================
module c061618g2_input_shield (
    input  [7:0] raw_ui,    // Raw incoming ui_in pad frame vector
    input  [7:0] raw_uio,   // Raw incoming uio_in pad frame vector
    output logic [7:0] safe_ui,   // Shielded, pure 2-state output wire bus
    output logic [7:0] safe_uio   // Shielded, pure 2-state output wire bus
);

    // =========================================================================
    // PROCEDURAL ISOLATION BOUNDARY
    // Placing these bit-by-bit inside an always_comb block forces Verilator
    // to drop the structural wire tracking graph, rendering them as clean variables.
    // =========================================================================
    always_comb begin
        // --- ui_in Channel Masking (Address Matrix & Map Controls) ---
        // Address lines A11-A15 default high (1'b1) via motherboard pull-ups
        assign safe_ui[0] = (raw_ui[0] === 1'bx || raw_ui[0] === 1'bz) ? 1'b1 : (raw_ui[0] == 1'b1); // A11
        assign safe_ui[1] = (raw_ui[1] === 1'bx || raw_ui[1] === 1'bz) ? 1'b1 : (raw_ui[1] == 1'b1); // A12
        assign safe_ui[2] = (raw_ui[2] === 1'bx || raw_ui[2] === 1'bz) ? 1'b1 : (raw_ui[2] == 1'b1); // A13
        assign safe_ui[3] = (raw_ui[3] === 1'bx || raw_ui[3] === 1'bz) ? 1'b1 : (raw_ui[3] == 1'b1); // A14
        assign safe_ui[4] = (raw_ui[4] === 1'bx || raw_ui[4] === 1'bz) ? 1'b1 : (raw_ui[4] == 1'b1); // A15
    
        // Active-low MMU map control defaults high (1'b1) to remain unasserted/idle
        assign safe_ui[5] = (raw_ui[5] === 1'bx || raw_ui[5] === 1'bz) ? 1'b1 : (raw_ui[5] == 1'b1); // map_n
    
        // Active-high cartridge lines default low (1'b0) via motherboard pull-downs
        assign safe_ui[6] = (raw_ui[6] === 1'bx || raw_ui[6] === 1'bz) ? 1'b0 : (raw_ui[6] == 1'b1); // rd4
        assign safe_ui[7] = (raw_ui[7] === 1'bx || raw_ui[7] === 1'bz) ? 1'b0 : (raw_ui[7] == 1'b1); // rd5


        // --- uio_in Channel Masking (Control Channels) ---
        // ren is active-high, so its safe boot baseline defaults low (1'b0)
        assign safe_uio[0] = (raw_uio[0] === 1'bx || raw_uio[0] === 1'bz) ? 1'b0 : (raw_uio[0] == 1'b1); // ren
    
        // Active-low control channels default high (1'b1) to remain unasserted/idle
        assign safe_uio[1] = (raw_uio[1] === 1'bx || raw_uio[1] === 1'bz) ? 1'b1 : (raw_uio[1] == 1'b1); // ref_n 
        assign safe_uio[2] = (raw_uio[2] === 1'bx || raw_uio[2] === 1'bz) ? 1'b1 : (raw_uio[2] == 1'b1); // mpd_n 
        assign safe_uio[3] = (raw_uio[3] === 1'bx || raw_uio[3] === 1'bz) ? 1'b1 : (raw_uio[3] == 1'b1); // be_n  
        assign safe_uio[6] = (raw_uio[6] === 1'bx || raw_uio[6] === 1'bz) ? 1'b1 : (raw_uio[6] == 1'b1); // FLG_IN_n


        // --- Unreferenced Padding Channels (Strips UNUSEDSIGNAL warnings completely) ---
        assign safe_uio[4] = (raw_uio[4] == 1'b1);
        assign safe_uio[5] = (raw_uio[5] == 1'b1);
        assign safe_uio[7] = (raw_uio[7] == 1'b1);
    end

endmodule

`default_nettype wire

`endif 

