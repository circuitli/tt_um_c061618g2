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
    input  wire  rst_n,
    input  wire  set,
    input  wire  hold,
    output logic q
);

    // =========================================================================
    // HARDENED MUX-BASED ASYNCHRONOUS LATCH
    // Replaces dangerous discrete logic feedback loops with a glitch-minimized
    // IHP SG130G2 hardware multiplexer cell.
    // =========================================================================
    
    (* keep = 1 *) wire mux_out;
    (* keep = 1 *) wire feedback_loop;

    `ifdef COCOTB_SIM
        // Prevent delta-cycle simulator lockups during zero-delay simulation
        assign #1 feedback_loop = q;
    `else
        assign feedback_loop = q;
    `endif

    // Functional Truth:
    // When 'set' is active (high), we force the latch to sample 'hold'.
    // When 'set' is inactive (low), the latch samples its own 'feedback_loop'.
    // Mapping the feedback network parameters to the safe async multiplexer:
    // a0 -> feedback_loop (Selected when set == 0)
    // a1 -> hold          (Selected when set == 1)
    // s  -> set           (Toggle select line)
    // y  -> mux_out       (Glitch-free result)
    safe_async_mux u_latch_mux (
        .a0 (feedback_loop),
        .a1 (hold),
        .s  (set),
        .y  (mux_out)
    );

    // Synchronous or Asynchronous clear path hookup
    assign q = rst_n ? mux_out : 1'b0;

endmodule

`default_nettype wire
`endif
