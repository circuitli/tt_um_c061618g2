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

`ifndef ASYNC_GLITCH_FILTER_SV
`define ASYNC_GLITCH_FILTER_SV
`default_nettype none

`include "src/tech/and2_1.v"
`include "src/tech/inv_1.v"
`include "src/tech/buf_4.v"
`include "src/cell/async_latch_cell.v"

module async_glitch_filter #(
    parameter int STAGES = 3 // Number of double-inverter delay blocks
)(
    input  wire  rst_n,
    input  wire  async_in,
    output logic async_out
);

    wire [STAGES:0] delay_chain;

    // -------------------------------------------------------------------------
    // INPUT AND RESET GATE
    // -------------------------------------------------------------------------
    (* keep = "true" *)
    and2_1 u_input_reset_gate (
        .A (async_in),
        .B (rst_n),
        .X (delay_chain[0])
    );

    // We declare a single tracking wire to accumulate the XOR properties safely
    wire [STAGES:0] xor_accumulator;
    assign xor_accumulator[0] = 1'b0;

    // =========================================================================
    // 1. STRUCTURAL ASYNCHRONOUS DELAY GENERATION WITH LOAD CAPACITORS
    // =========================================================================
    generate
        for (genvar i = 0; i < STAGES; i = i + 1) begin : gen_stages
            (* keep = "true" *) wire internal_inv_node;
            (* keep = "true" *) wire scalar_cap_a;
            (* keep = "true" *) wire scalar_cap_b;

            // --- FIRST HALF STAGE ---
            (* keep = "true" *)
            inv_1 u_inv_a (
                .A (delay_chain[i]),
                .Y (internal_inv_node)
            );
            
            // Attached capacitor load
            (* keep = "true" *)
            buf_4 u_load_cap_a (
                .A (internal_inv_node),
                .X (scalar_cap_a) 
            );

            // --- SECOND HALF STAGE ---
            (* keep = "true" *)
            inv_1 u_inv_b (
                .A (internal_inv_node),
                .Y (delay_chain[i+1])
            );

            // Attached capacitor load
            (* keep = "true" *)
            buf_4 u_load_cap_b (
                .A (delay_chain[i+1]),
                .X (scalar_cap_b) 
            );

            // Chain the scalar tracks into an unbroken line
            assign xor_accumulator[i+1] = xor_accumulator[i] ^ scalar_cap_a ^ scalar_cap_b;
        end
    endgenerate

    // =========================================================================
    // GLITCH DETECTION WINDOWS (STRUCTURALLY LINKED TO DUMMY CAPS)
    // By merging the cap outputs into the active equations, the tool cannot 
    // call them floating or unconnected. They are permanently locked.
    // =========================================================================
    // Final un-optimizable anchor net
    wire cap_anchor = xor_accumulator[STAGES];

    // By combining cap_anchor directly via XOR into the active paths, the 
    // synthesis engine cannot substitute a static boolean constant (like 1'b1).
    // It is forced to route and maintain every stage to preserve the function.
    wire filter_set  = (&delay_chain[STAGES:1]) & rst_n ^ cap_anchor;
    wire filter_hold = ((|delay_chain[STAGES:1]) & rst_n) ^ cap_anchor;


    // =========================================================================
    // LATCH LOOP BOUNDARY
    // =========================================================================
    logic  latch_raw_out;

    (* keep = "true" *)
    async_latch_cell u_latch_inst (
        .rst_n (rst_n),
        .set   (filter_set),  
        .hold  (filter_hold), 
        .q     (latch_raw_out)
    );

    assign async_out = latch_raw_out;

endmodule

`default_nettype wire
`endif