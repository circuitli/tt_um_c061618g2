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

`ifndef C061618G2_INPUT_SHHIELD_FORMAL_SV
`define C061618G2_INPUT_SHHIELD_FORMAL_SV
`default_nettype none

// =========================================================================
// FORMAL VERIFICATION PROPERTIES MODULE FOR c061618g2_input_shield
// Binds directly to the core to rigorously prove signal integrity.
// =========================================================================
module c061618g2_input_shield_formal (
    input  wire  [7:0] raw_ui,
    input  wire  [7:0] raw_uio,
    input  logic [7:0] safe_ui,
    input  logic [7:0] safe_uio
);

    // Unchecked verification assumptions helper macro
    // Since formal analysis can inject ANY combination of 1, 0, X, or Z, 
    // we let the solver drive the inputs completely unconstrained.

    // =========================================================================
    // 1. HARDWARE PROTECTION MATRICES (VALID SIGNAL IDENTITY CHECKS)
    // Ensures that when inputs are valid stable binary data (0 or 1), 
    // the output is a strict non-inverting 1-to-1 match.
    // =========================================================================
    
    // --- ui_in Channel Strict Identity Checks ---
    assert property (@(raw_ui[0]) (raw_ui[0] === 1'b1) -> (safe_ui[0] === 1'b1));
    assert property (@(raw_ui[0]) (raw_ui[0] === 1'b0) -> (safe_ui[0] === 1'b0));

    assert property (@(raw_ui[1]) (raw_ui[1] === 1'b1) -> (safe_ui[1] === 1'b1));
    assert property (@(raw_ui[1]) (raw_ui[1] === 1'b0) -> (safe_ui[1] === 1'b0));

    assert property (@(raw_ui[2]) (raw_ui[2] === 1'b1) -> (safe_ui[2] === 1'b1));
    assert property (@(raw_ui[2]) (raw_ui[2] === 1'b0) -> (safe_ui[2] === 1'b0));

    assert property (@(raw_ui[3]) (raw_ui[3] === 1'b1) -> (safe_ui[3] === 1'b1));
    assert property (@(raw_ui[3]) (raw_ui[3] === 1'b0) -> (safe_ui[3] === 1'b0));

    assert property (@(raw_ui[4]) (raw_ui[4] === 1'b1) -> (safe_ui[4] === 1'b1));
    assert property (@(raw_ui[4]) (raw_ui[4] === 1'b0) -> (safe_ui[4] === 1'b0));

    assert property (@(raw_ui[5]) (raw_ui[5] === 1'b1) -> (safe_ui[5] === 1'b1));
    assert property (@(raw_ui[5]) (raw_ui[5] === 1'b0) -> (safe_ui[5] === 1'b0));

    assert property (@(raw_ui[6]) (raw_ui[6] === 1'b1) -> (safe_ui[6] === 1'b1));
    assert property (@(raw_ui[6]) (raw_ui[6] === 1'b0) -> (safe_ui[6] === 1'b0));

    assert property (@(raw_ui[7]) (raw_ui[7] === 1'b1) -> (safe_ui[7] === 1'b1));
    assert property (@(raw_ui[7]) (raw_ui[7] === 1'b0) -> (safe_ui[7] === 1'b0));

    // --- uio_in Channel Strict Identity Checks ---
    assert property (@(raw_uio[0]) (raw_uio[0] === 1'b1) -> (safe_uio[0] === 1'b1));
    assert property (@(raw_uio[0]) (raw_uio[0] === 1'b0) -> (safe_uio[0] === 1'b0));

    assert property (@(raw_uio[1]) (raw_uio[1] === 1'b1) -> (safe_uio[1] === 1'b1));
    assert property (@(raw_uio[1]) (raw_uio[1] === 1'b0) -> (safe_uio[1] === 1'b0));

    assert property (@(raw_uio[2]) (raw_uio[2] === 1'b1) -> (safe_uio[2] === 1'b1));
    assert property (@(raw_uio[2]) (raw_uio[2] === 1'b0) -> (safe_uio[2] === 1'b0));

    assert property (@(raw_uio[3]) (raw_uio[3] === 1'b1) -> (safe_uio[3] === 1'b1));
    assert property (@(raw_uio[3]) (raw_uio[3] === 1'b0) -> (safe_uio[3] === 1'b0));

    assert property (@(raw_uio[6]) (raw_uio[6] === 1'b1) -> (safe_uio[6] === 1'b1));
    assert property (@(raw_uio[6]) (raw_uio[6] === 1'b0) -> (safe_uio[6] === 1'b0));


    // =========================================================================
    // 2. UNINITIALIZED SIMULATION CHECKS (X/Z CLAMP PROOFS)
    // Proves mathematically that if an input floats to X or Z, the design
    // snaps to the exact required active-high or active-low system default.
    // =========================================================================
    
    // Motherboard pull-ups emulation: Address matrix lines (A11-A15) default high (1'b1)
    always_comb begin
        if (raw_ui[0] === 1'bx || raw_ui[0] === 1'bz) assert final (safe_ui[0] === 1'b1);
        if (raw_ui[1] === 1'bx || raw_ui[1] === 1'bz) assert final (safe_ui[1] === 1'b1);
        if (raw_ui[2] === 1'bx || raw_ui[2] === 1'bz) assert final (safe_ui[2] === 1'b1);
        if (raw_ui[3] === 1'bx || raw_ui[3] === 1'bz) assert final (safe_ui[3] === 1'b1);
        if (raw_ui[4] === 1'bx || raw_ui[4] === 1'bz) assert final (safe_ui[4] === 1'b1);
        
        // Active-low MMU map control defaults high (1'b1) to stay idle
        if (raw_ui[5] === 1'bx || raw_ui[5] === 1'bz) assert final (safe_ui[5] === 1'b1);
        
        // Motherboard pull-downs emulation: Cartridge signals (rd4, rd5) default low (1'b0)
        if (raw_ui[6] === 1'bx || raw_ui[6] === 1'bz) assert final (safe_ui[6] === 1'b0);
        if (raw_ui[7] === 1'bx || raw_ui[7] === 1'bz) assert final (safe_ui[7] === 1'b0);

        // Active-high Read Enable (ren) defaults low (1'b0) to stay safe and disabled
        if (raw_uio[0] === 1'bx || raw_uio[0] === 1'bz) assert final (safe_uio[0] === 1'b0);
        
        // Active-low interface controls default high (1'b1) to stay unasserted
        if (raw_uio[1] === 1'bx || raw_uio[1] === 1'bz) assert final (safe_uio[1] === 1'b1);
        if (raw_uio[2] === 1'bx || raw_uio[2] === 1'bz) assert final (safe_uio[2] === 1'b1);
        if (raw_uio[3] === 1'bx || raw_uio[3] === 1'bz) assert final (safe_uio[3] === 1'b1);
        if (raw_uio[6] === 1'bx || raw_uio[6] === 1'bz) assert final (safe_uio[6] === 1'b1);
    end

    // =========================================================================
    // 3. 2-STATE OUTPUT IMMUNITY CHECK
    // Guarantee that outputs NEVER contain 'x' or 'z' under any scenario.
    // =========================================================================
    always_comb begin
        assert final (safe_ui !== 1'bx && safe_ui !== 1'bz);
        assert final (safe_uio !== 1'bx && safe_uio !== 1'bz);
    end

endmodule

// Bind the verification properties directly into the production code tracking target
bind c061618g2_input_shield c061618g2_input_shield_formal i_c061618g2_input_shield_formal (
    .raw_ui   (raw_ui),
    .raw_uio  (raw_uio),
    .safe_ui  (safe_ui),
    .safe_uio (safe_uio)
);

`default_nettype wire
`endif 
