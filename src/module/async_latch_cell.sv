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

`ifndef ASYNC_LATCH_CELL_SV
`define ASYNC_LATCH_CELL_SV
 
`default_nettype none

`include "src/module/safe_async_mux.sv"

module async_latch_cell (
    input  wire  rst_n, // Asynchronous active-low reset
    input  wire  set,   // Toggle select line
    input  wire  hold,  // Data input sampled when set is high
    output logic q      // Fully reset-safe latch output
);

    // =========================================================================
    // HARDENED MUX-BASED ASYNCHRONOUS LATCH WITH FULL LOOP CLEARING
    // Replaces discrete logic feedback loops with a glitch-minimized
    // safe multiplexer cell, ensuring zero residual feedback during reset.
    // =========================================================================
    
    (* keep = 1 *) wire mux_out;
    (* keep = 1 *) wire feedback_loop;

    `ifdef COCOTB_SIM
        // Prevent delta-cycle simulator lockups during zero-delay simulation
        // The feedback loop is explicitly zeroed when rst_n goes low
        assign #1 feedback_loop = rst_n ? q : 1'b0;
    `else
        // Structural fix: Clears the feedback channel instantly on reset
        assign feedback_loop = rst_n ? q : 1'b0;
    `endif

    // Functional Truth:
    // When 'set' is active (high), we force the latch to sample 'hold'.
    // When 'set' is inactive (low), the latch samples its own 'feedback_loop'.
    // mapping parameters to the safe async multiplexer:
    // a0 -> feedback_loop (Selected when set == 0)
    // a1 -> hold          (Selected when set == 1)
    // s  -> set           (Toggle select line)
    // y  -> mux_out       (Glitch-free result)
    safe_async_mux u_latch_mux (
        .rst_n (rst_n),
        .a0    (feedback_loop),
        .a1    (hold),
        .s     (set),
        .y     (mux_out)
    );

    // Secure Output Boundary: Prevents uninitialized states or glitches 
    // from sneaking past the latch core when rst_n drops to 0.
    assign q = rst_n ? mux_out : 1'b0;

endmodule

`default_nettype wire
`endif
