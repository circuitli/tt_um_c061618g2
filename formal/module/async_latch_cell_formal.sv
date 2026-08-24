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
    input wire q,
    input wire rst_n,
    input wire set,
    input wire hold
);

    assert_primitive_reset_override: assert property (
        (rst_n) || (q == 1'b0)
    );

    assert_primitive_set_priority: assert property (
        ! (rst_n && set) || (q == 1'b1)
    );

    assert_primitive_hold_stability: assert property (
        ! (rst_n && !set && hold && q) || (q == 1'b1)
    );

    assert_primitive_clear_on_hold_collapse: assert property (
        ! (rst_n && !set && !hold) || (q == 1'b0)
    );

endmodule

// Injects the properties directly around the outer cell instance interface
bind async_latch_cell async_latch_cell_formal i_async_latch_cell_formal (
    .q     (q),
    .rst_n (rst_n),
    .set   (set),
    .hold  (hold)
);

`endif
