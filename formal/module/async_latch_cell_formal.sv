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

`ifndef ASYNC_LATCH_CELL_FORMAL_SV
`define ASYNC_LATCH_CELL_FORMAL_SV
 
`default_nettype none

module async_latch_cell_formal (
    input  wire  rst_n,
    input  wire  set,
    input  wire  hold,
    input  wire  q
);

`ifdef FORMAL

    // -------------------------------------------------------------------------
    // 1. ASYNCHRONOUS RESET PROOF
    // Property: Whenever rst_n is pulled low, the latch output must drop to 0 
    // instantly, completely ignoring the 'set' and 'hold' lines.
    // -------------------------------------------------------------------------
    asm_latch_reset_assert: assert property (
        (!rst_n) -> (q == 1'b0)
    );

    // -------------------------------------------------------------------------
    // 2. TRANSPARENT SAMPLING PROOF (DATA PASS-THROUGH)
    // Property: When rst_n is inactive and 'set' is high, the latch cell 
    // must act completely transparently, driving 'q' to match 'hold'.
    // -------------------------------------------------------------------------
    asm_latch_sample_assert: assert property (
        (rst_n && set) -> (q == hold)
    );

    // -------------------------------------------------------------------------
    // 3. ASYNCHRONOUS STATE HOLD PROOF
    // Property: When 'set' drops low, the circuit enters memory mode. The output
    // at the next evaluation phase must mirror the immediate past value of 'q',
    // provided a reset event does not occur.
    // -------------------------------------------------------------------------
    asm_latch_hold_assert: assert property (
        (rst_n && $past(rst_n) && !set) -> (q == $past(q))
    );

    // -------------------------------------------------------------------------
    // 4. METASTABILITY & X-PROPAGATION BARRIER PROOF
    // Property: The latch output port must remain strictly binary under all 
    // valid or pseudo-valid operational states to protect downstream logic.
    // -------------------------------------------------------------------------
    asm_latch_binary_assert: assert property (
        (q == 1'b1) || (q == 1'b0)
    );

`endif

endmodule

// Injects the properties directly around the outer cell instance interface
bind async_latch_cell async_latch_cell_formal i_async_latch_cell_formal (
    .rst_n (rst_n),
    .set   (set),
    .hold  (hold),
    .q     (q)
);

`endif
