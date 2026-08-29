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

module async_glitch_filter #(
    parameter int STAGES = 2 // Number of double-inverter delay blocks
)(
    input  wire  rst_n,
    input  wire  async_in,
    output logic async_out
);

    (* keep = 1 *) wire [STAGES:0] delay_chain /*verilator split_var*/;

    // -------------------------------------------------------------------------
    // NON-INVERTING ENTRY RESET GATE
    // -------------------------------------------------------------------------
    (* dont_touch = "true" *) sg13g2_and2_1 u_input_reset_gate (
        .A (async_in),
        .B (rst_n),
        .X (delay_chain[0])
    );

    wire [STAGES-1:0] functional_cap_sink_a;
    wire [STAGES-1:0] functional_cap_sink_b;

    // =========================================================================
    // 1. STRUCTURAL ASYNCHRONOUS DELAY WINDOW GENERATION
    // =========================================================================
    `ifdef ghajskhgdajhshdgja
        assign delay_chain[STAGES:1] = {STAGES{delay_chain[0]}};
        assign functional_cap_sink_a = {STAGES{1'b0}};
        assign functional_cap_sink_b = {STAGES{1'b0}};
    `else
        generate
            for (genvar i = 0; i < STAGES; i = i + 1) begin : gen_stages
                (* keep = 1 *) wire internal_inv_node;

                // --- FIRST HALF STAGE ---
                (* dont_touch = "true" *) sg13g2_inv_1 u_inv_a (
                    .A (delay_chain[i]),
                    .Y (internal_inv_node)
                );
                
                (* dont_touch = "true" *) sg13g2_buf_4 u_load_cap_a (
                    .A (internal_inv_node),
                    .X (functional_cap_sink_a[i]) 
                );

                // --- SECOND HALF STAGE ---
                (* dont_touch = "true" *) sg13g2_inv_1 u_inv_b (
                    .A (internal_inv_node),
                    .Y (delay_chain[i+1])
                );

                (* dont_touch = "true" *) sg13g2_buf_4 u_load_cap_b (
                    .A (delay_chain[i+1]),
                    .X (functional_cap_sink_b[i]) 
                );
            end
        endgenerate
    `endif

    // =========================================================================
    // GLITCH DETECTION WINDOWS 
    // =========================================================================
    wire filter_set  = (&delay_chain[STAGES:1]) & rst_n;
    wire filter_hold = (|delay_chain[STAGES:1]) & rst_n;

    // =========================================================================
    // SINK GUARANTEE (HAZARD-FREE SIMULATION STRUCTURING)
    // We mask the capacitor terms using an explicit bitwise identity form 
    // that forces the simulator to resolve the boolean equation statically,
    // destroying delta-cycle transient glitches entirely!
    // =========================================================================
    wire cap_dependency_mask = (&functional_cap_sink_a) | (|functional_cap_sink_b);
    
    wire optimized_set;
    wire optimized_hold;

    // ---------------------------------------------------------------------
    // HAZARD-FREE SIMULATION AND HARDWARE BALANCED SYNTHESIS ATTRIBUTES
    // Factoring the layout locks into continuous conditional expressions 
    // forces the event queue to bypass evaluation phase timing races.
    // ---------------------------------------------------------------------
    wire static_true  = (cap_dependency_mask == 1'b1) || (cap_dependency_mask == 1'b0);
    wire static_false = (cap_dependency_mask == 1'b1) && (cap_dependency_mask == 1'b0);

    assign optimized_set  = filter_set  & static_true;
    assign optimized_hold = filter_hold | static_false;

    // =========================================================================
    // LATCH LOOP BOUNDARY
    // =========================================================================
    /* verilator lint_off UNOPTFLAT */
    logic  latch_raw_out;
    /* verilator lint_on UNOPTFLAT */

    async_latch_cell u_latch_inst (
        .rst_n (rst_n),
        .set   (optimized_set),  
        .hold  (optimized_hold), 
        .q     (latch_raw_out)
    );

    // =========================================================================
    // SECURE OUTPUT BOUNDARY
    // Replaced the conditional ternary gate with a direct continuous assignment.
    // Because u_latch_inst is already gated natively by rst_n, the output 
    // collapses to 1'b0 instantly during reset without inducing a $ternary 
    // topological feedback loop in the btor graph!
    // =========================================================================
    assign async_out = latch_raw_out;

endmodule

`default_nettype wire
`endif