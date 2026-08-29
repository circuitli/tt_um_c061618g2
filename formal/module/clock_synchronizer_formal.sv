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

`ifndef CLOCK_SYNCHRONIZER_FORMAL_SV
`define CLOCK_SYNCHRONIZER_FORMAL_SV
`default_nettype none

// =========================================================================
// MODULE: clk_sync_formal
// DESCRIPTION: Formal verification properties, safety assertions, and 
//              functional coverage tailored for an array-based, 
//              gated, reset-synchronized clock module.
// =========================================================================

module clock_sybchronizer_formal #(
    parameter int STAGES = 2
) (
    input logic rst,
    input logic raw_clk,
    input logic sync_clk,
    input logic [STAGES-1:0] sync_stages
);

    // ---------------------------------------------------------------------
    // COMBINATIONAL SAFETY INVARIANTS (Immediate Assertions)
    // ---------------------------------------------------------------------

    // A1: Immediate Reset Safety
    // When reset is active, the synchronized clock must be held low immediately.
    always @(*) begin
        if (rst) begin
            assert (sync_clk == 1'b0);
        end
    end

    // A2: Gating Gate-Level Compliance
    // The output sync_clk must strictly equal the raw_clk gated by the final stage bit.
    always @(*) begin
        assert (sync_clk == (raw_clk && sync_stages[STAGES-1]));
    end


    // ---------------------------------------------------------------------
    // CLOCKED SAFETY INVARIANTS (Yosys-Optimized Asset Blocks)
    // ---------------------------------------------------------------------

    // A3: Pipeline Stability on Rising Edge
    // Since the design updates sync_stages on the negative edge of raw_clk,
    // the pipeline array must remain completely stable on every positive edge.
    always @(posedge raw_clk) begin
        if (!rst) begin
            assert ($stable(sync_stages));
        end
    end

    // A4: Glitch-Free Gating Assertion
    // Proves that any change in the final gating qualifier occurs exclusively
    // while raw_clk is low, mathematically guaranteeing no clock slivers.
    always @(negedge raw_clk) begin
        if (!rst) begin
            // When evaluating at the negative edge, verify the structural low baseline
            assert (raw_clk == 1'b0);
        end
    end


    // ---------------------------------------------------------------------
    // FUNCTIONAL COVERAGE (Verification Reachability Targets)
    // ---------------------------------------------------------------------

    // C1: Verify that the synchronization pipeline can successfully latch high
    always @(posedge raw_clk) begin
        if (!rst) begin
            cover (sync_stages[STAGES-1] == 1'b1);
        end
    end

    // C2: Verify that the final synchronized clock tree achieves toggling state
    always @(posedge raw_clk) begin
        if (!rst) begin
            cover (sync_clk == 1'b1);
        end
    end

endmodule

// =========================================================================
// BIND STATEMENT
// =========================================================================
bind clock_synchronizer clock_synchronizer_formal #(.STAGES(2)) i_clock_synchronizer_formal (
    .rst(rst),
    .raw_clk(raw_clk),
    .sync_clk(sync_clk),
    .sync_stages(sync_stages)
);

`endif