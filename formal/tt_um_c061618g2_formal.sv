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
 
`ifndef TT_UM_C061618G2_FORMAL_SV
`define TT_UM_C061618G2_FORMAL_SV

`default_nettype none

module tt_um_c061618g2_formal (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high)
    input  wire       ena,      // Core clock enable string
    input  wire       clk,      // System clock
    input  wire       rst_n     // Active-low asynchronous reset
);

    // ----------------------------------------------------------------
    // 1. Internal Signal Declarations & Clock/Reset Logic
    // ----------------------------------------------------------------
    // Invert the active-low reset to make formal logic loops simpler to read
    wire rst = !rst_n;

    // ----------------------------------------------------------------
    // 2. Hardware Design Under Test (DUT) Instantiation
    // ----------------------------------------------------------------
    // Links directly to your core module implementation layout
    tt_um_c061618g2 dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // ----------------------------------------------------------------
    // 3. Formal Verification Assertions Engine (SBY Compatible)
    // ----------------------------------------------------------------
    `ifdef FORMAL
    
    // Step Monitor: Tracks if the simulation loop has advanced past the first cycle
    reg f_past_valid = 1'b0;
    always @(posedge clk) begin
        f_past_valid <= 1'b1;
    end

    // ----------------------------------------------------------------
    // Global Subsystem Assumptions
    // ----------------------------------------------------------------
    always @(*) begin
        // Assume the clock enable line remains tied high during formal sequence analysis
        assume(ena == 1'b1);
    end

    // ----------------------------------------------------------------
    // Procedural Immediate Assertions & Assumptions
    // (Replaces the broken 'assert property' syntax block smoothly)
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        
        // Target Reset Behavior Checking
        if (rst) begin
            assert(uo_out == 8'b00000000);
            assert(uio_out == 8'b00000000);
        end
        
        // Post-Reset Functional Cycle Safety Checking
        if (f_past_valid && !$past(rst)) begin
            
            /* 
             * EXAMPLES: How to translate concurrent SVA properties into immediate assertions:
             *
             * Old Broken SVA Format: 
             *   assert property (@(posedge clk) disable iff(rst) ui_in[0] |=> uo_out[0]);
             *
             * Corrected Yosys/SBY Format:
             */
            if ($past(ui_in[0])) begin
                assert(uo_out[0] == 1'b1);
            end

            // Example 2: Memory Access Guard Condition
            // If write enable and read enable are mutually exclusive in your MMU core
            if ($past(ui_in[7]) && $past(ui_in[6])) begin
                assert(uo_out[7] == 1'b1); // Enforce error bit assertion flag
            end
            
        end
    end

    // ----------------------------------------------------------------
    // Coverage Validation Points
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (f_past_valid && !rst) begin
            // Verify that a valid configuration write execution path is reachable
            cover(ui_in[7] == 1'b1 && uo_out[7] == 1'b0);
            
            // Verify the design escapes the initialization reset cycle cleanly
            cover($past(rst) && !rst);
        end
    end

    `endif

endmodule



// Bind statement mapping outer physical tile pin networks straight to verification monitors
bind tt_um_c061618g2 tt_um_c061618g2_formal i_tt_um_c061618g2_formal (
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (uio_in),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (ena),
    .clk     (clk),
    .rst_n   (rst_n)
);

`endif