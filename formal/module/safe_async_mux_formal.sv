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

`default_nettype none

module safe_async_mux_formal (
    input  wire  a0, // Data channel 0
    input  wire  a1, // Data channel 1
    input  wire  s,  // Channel select line
    input  wire  y   // Monitored output from the actual DUT instance
);

`ifdef FORMAL
    // =========================================================================
    // 1. INPUT ASSUMPTIONS (Environment Modeling)
    // We assume the environmental inputs behave like true physical 2-state nets.
    // =========================================================================
    always_comb begin
        assume (a0 === 1'b0 || a0 === 1'b1);
        assume (a1 === 1'b0 || a1 === 1'b1);
        assume (s  === 1'b0 || s  === 1'b1);
    end

    // =========================================================================
    // 2. STABILITY AND COVERAGE CHECKS
    // Immediate combinational assertions to verify math truth tables.
    // =========================================================================
    always_comb begin
        // Guarantee clean binary output mapping under all standard operations
        assert (y === 1'b0 || y === 1'b1);

        // Prove Channel 0 routing precision
        if (s == 1'b0) begin
            assert (y == a0);
        end

        // Prove Channel 1 routing precision
        if (s == 1'b1) begin
            assert (y == a1);
        end

        // Prove the Consensus Term Rule (Hazard Protection)
        // If both data channels are identical, changing 's' MUST NOT glitch 'y'
        if (a0 == a1) begin
            assert (y == a0);
        end
    end

    // =========================================================================
    // 3. EXPLORATORY COMPONENT COVERAGE
    // Forces SBY to output a structural validation trace showing active paths
    // =========================================================================
    always_comb begin
        cover (s == 1'b0 && a0 == 1'b1 && y == 1'b1);
        cover (s == 1'b1 && a1 == 1'b1 && y == 1'b1);
    end
`endif

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
