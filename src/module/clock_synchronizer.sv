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

`ifndef CLOCK_SYNCHRONIZER_SV
`define CLOCK_SYNCHRONIZER_SV
`default_nettype none

// =========================================================================
// MODULE: clock_synchronizer
// DESCRIPTION: Glitch-free reset-synchronized clock module using a packed
//              array (vector shift register) instead of discrete scalar 
//              registers for the synchronization pipeline stages.
// =========================================================================

(* keep_hierarchy = 1 *)
module clock_synchronizer #(
    parameter int STAGES = 2 
) (
    input  logic rst,        // Asynchronous system reset input
    input  logic raw_clk,    // Asynchronous or raw input clock source
    output logic sync_clk    // Stabilized, glitch-free synchronized clock output
);

    // Multi-stage synchronization array vector with synthesis attributes
    // to prevent primitive remapping and minimize physical routing delay.
    (* async_reg = "true" *) logic [STAGES-1:0] sync_stages;

    // ---------------------------------------------------------------------
    // Sequential Gating Logic
    // ---------------------------------------------------------------------
    // The stages are clocked on the falling edge (negedge) of the raw clock.
    // This holds the un-gating control signal low until raw_clk is low, 
    // guaranteeing that the clock gate opens without clipping or slivers.
    
    always_ff @(negedge raw_clk or posedge rst) begin
        if (rst) begin
            // Clear the entire shift register pipeline instantly on reset
            sync_stages <= '0;
        end else begin
            // Concatenation shift operation: move bits left and shift in a solid 1
            sync_stages <= {sync_stages[STAGES-2:0], 1'b1};
        end
    end

    // Clock gate combination logic. Using negedge flip-flops ensures that
    // the gating control signal changes only when raw_clk is low, completely
    // eliminating narrow clock pulse anomalies or sliver hazards.
    assign sync_clk = raw_clk & sync_stages[STAGES-1];

endmodule

`endif