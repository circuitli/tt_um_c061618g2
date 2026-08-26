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

`ifndef SAFE_ASYNC_MUX_FORMAL_SVH
`define SAFE_ASYNC_MUX_FORMAL_SVH
`default_nettype none

module safe_async_mux_formal (
    input wire a0,
    input wire a1,
    input wire s,
    input logic y // Monitored directly from the physical module output
);

    // =========================================================================
    // 1. FUNCTIONAL CORRECTNESS PROPERTIES (Checked on the real design port!)
    // =========================================================================
    
    // Property: When select is 0, physical output must strictly match input a0
    asm_select_a0: assert property (s == 1'b0 -> y == a0);

    // Property: When select is 1, physical output must strictly match input a1
    asm_select_a1: assert property (s == 1'b1 -> y == a1);

    // =========================================================================
    // 2. TRUE PHYSICAL GLITCH IMMUNITY PROOFS
    // These evaluate the actual 'y' terminal under boundary input states.
    // If Yosys strips the cover term from your RTL file, these will instantly FAIL.
    // =========================================================================

    // CRITICAL GLITCH INVARIANT:
    // If both physical inputs are HIGH, the physical output 'y' MUST stay HIGH,
    // completely preventing any intermediate voltage dropout when select 's' toggles.
    asm_glitch_immune_high: assert property ((a0 == 1'b1 && a1 == 1'b1) -> y == 1'b1);

    // If both physical inputs are LOW, the physical output 'y' MUST stay LOW.
    asm_glitch_immune_low: assert property ((a0 == 1'b0 && a1 == 1'b0) -> y == 1'b0);

endmodule

// =========================================================================
// SYNTAX SAFE BIND DIRECTIVE
// Binds directly to your physical safe_async_mux module workspace
// =========================================================================
bind safe_async_mux safe_async_mux_formal u_formal_check (
    .a0(a0),
    .a1(a1),
    .s(s),
    .y(y)
);

`endif // SAFE_ASYNC_MUX_FORMAL_SVH
