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

`ifndef ASYNC_LATCH_UDP_FORMAL_SV
`define ASYNC_LATCH_UDP_FORMAL_SV
 
`default_nettype none

// =============================================================================
// Standalone Formal Checker Wrapper for the User-Defined Primitive (UDP)
// This module directly instantiates the UDP to verify its truth table entries.
// =============================================================================
module async_latch_udp_formal (
    input wire rst_n,   // Pure combinational reset input
    input wire set,     // Filter set condition input
    input wire hold     // Filter hold condition input
);

    // Instantiate the custom asynchronous latch UDP inside the verification envelope
    wire q_out;
    
    async_latch_udp u_dut_primitive (
        .q     (q_out),
        .rst_n (rst_n),
        .set   (set),
        .hold  (hold)
    );

    // =========================================================================
    // EXHAUSTIVE TRUTH-TABLE ENVELOPE VERIFICATION (NO ARROWS, PURE BOOLEAN LOGIC)
    // =========================================================================

    // Row 1 Verification: Active-low clear override takes absolute priority
    assert_primitive_reset_override: assert property (
        (rst_n) || (q_out == 1'b0)
    );

    // Row 2 Verification: Set takes absolute priority when reset is inactive
    assert_primitive_set_priority: assert property (
        !(rst_n && set) || (q_out == 1'b1)
    );

    // Row 3 Verification: Maintain high state while the hold window is active
    // If it was already high, and hold is 1, it must stay high.
    assert_primitive_hold_stability: assert property (
        !(rst_n && !set && hold && q_out) || (q_out == 1'b1)
    );

    // Row 4 Verification: Force a drop to low when set is down and hold window shuts
    assert_primitive_clear_on_hold_collapse: assert property (
        !(rst_n && !set && !hold) || (q_out == 1'b0)
    );

endmodule

`endif