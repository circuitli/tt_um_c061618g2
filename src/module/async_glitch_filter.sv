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

`ifndef ASYNC_GLITCH_FILTER_SVH
`define ASYNC_GLITCH_FILTER_SVH
`default_nettype none

`include "src/module/async_latch_cell.sv"

// Relies on SYNTH_DONT_TOUCH workaround!!!
module async_glitch_filter #(
    parameter int STAGES = 2 // Number of double-inverter delay blocks
)(
    input  wire  rst_n,
    input  wire  async_in,
    output logic async_out
);

    wire [STAGES:0] delay_chain;

    // -------------------------------------------------------------------------
    // INPUT AND RESET GATE
    // -------------------------------------------------------------------------
    sg13g2_and2_1 u_input_reset_gate (
        .A (async_in),
        .B (rst_n),
        .X (delay_chain[0])
    );

    // =========================================================================
    // 1. STRUCTURAL ASYNCHRONOUS DELAY WINDOW GENERATION WITH CAPACITORS
    // =========================================================================
    generate
        for (genvar i = 0; i < STAGES; i = i + 1) begin : gen_stages
            (* keep = 1 *) wire internal_inv_node;
            (* keep = 1 *) wire cap_sink_a;
            (* keep = 1 *) wire cap_sink_b;

            // --- FIRST HALF STAGE ---
            sg13g2_inv_1 u_inv_a (
                .A (delay_chain[i]),
                .Y (internal_inv_node)
            );
            
            // Attached capacitor load
            sg13g2_buf_4 u_load_cap_a (
                .A (internal_inv_node),
                .X (cap_sink_a) 
            );

            // --- SECOND HALF STAGE ---
            sg13g2_inv_1 u_inv_b (
                .A (internal_inv_node),
                .Y (delay_chain[i+1])
            );

            // Attached capacitor load
            sg13g2_buf_4 u_load_cap_b (
                .A (delay_chain[i+1]),
                .X (cap_sink_b) 
            );
        end
    endgenerate

    // =========================================================================
    // GLITCH DETECTION WINDOWS 
    // =========================================================================
    wire filter_set  = (&delay_chain[STAGES:1]) & rst_n;
    wire filter_hold = (|delay_chain[STAGES:1]) & rst_n;

    // =========================================================================
    // LATCH LOOP BOUNDARY
    // =========================================================================
    logic  latch_raw_out;

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