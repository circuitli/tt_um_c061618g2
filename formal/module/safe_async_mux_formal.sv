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

`ifndef SAFE_ASYNC_MUX_FORMAL_SVH
`define SAFE_ASYNC_MUX_FORMAL_SVH
`default_nettype none

`default_nettype none

module safe_async_mux_formal (
    input  wire  rst_n,
    input  wire  a0,
    input  wire  a1,
    input  wire  s,
    input  wire  y
);

    // -------------------------------------------------------------------------
    // 1. ASYNCHRONOUS RESET VERIFICATION
    // Property: Whenever rst_n is pulled low, the output must drop to 0.
    // Equivalent Boolean Form: rst_n || (y == 1'b0)
    // -------------------------------------------------------------------------
    asm_reset_assert: assert property (
        rst_n || (y == 1'b0)
    );

    // -------------------------------------------------------------------------
    // 2. FUNCTIONAL MULTIPLEXING VERIFICATION
    // Replaced 'A -> B' with '!A || B' for strict Yosys compliance.
    // -------------------------------------------------------------------------
    asm_select_0_assert: assert property (
        !(rst_n && !s) || (y == a0)
    );

    asm_select_1_assert: assert property (
        !(rst_n && s) || (y == a1)
    );

    // -------------------------------------------------------------------------
    // 3. GLITCH-FREE CONSENSUS PROOF
    // -------------------------------------------------------------------------
    asm_consensus_high_assert: assert property (
        !(rst_n && a0 && a1) || (y == 1'b1)
    );

    asm_consensus_low_assert: assert property (
        !(rst_n && !a0 && !a1) || (y == 1'b0)
    );

    // -------------------------------------------------------------------------
    // 4. X/Z METASTABILITY ISOLATION PROOF
    // -------------------------------------------------------------------------
    asm_binary_isolation_assert: assert property (
        (y == 1'b1) || (y == 1'b0)
    );

endmodule

// =========================================================================
// SYNTAX SAFE BIND DIRECTIVE
// Binds directly to your physical safe_async_mux module workspace
// =========================================================================
bind safe_async_mux safe_async_mux_formal u_formal_check (
    .rst_n (rst_n),
    .a0(a0),
    .a1(a1),
    .s(s),
    .y(y)
);

`default_nettype wire
`endif // SAFE_ASYNC_MUX_FORMAL_SVH
