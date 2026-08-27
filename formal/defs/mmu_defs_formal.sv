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
 
`ifndef MMU_DEFS_FORMAL_SV
`define MMU_DEFS_FORMAL_SV

`default_nettype none
`include "src/defs/mmu_defs.sv"

// =========================================================================
// PURE FORMAL SYNTHESIS BLACKBOX STUBS FOR IHP CELLS
// Provides explicit, hardcoded interfaces to bypass hierarchy errors.
// =========================================================================

(* blackbox *)
module sg13g2_buf_4 (
    input  wire I,
    output wire Y
);
endmodule

(* blackbox *)
module sg13g2_inv_1 (
    input  wire A,
    output wire Y
);
endmodule

(* blackbox *)
module sg13g2_and2_1 (
    input  wire A,
    input  wire B,
    output wire X
);
endmodule

module mmu_defs_formal(
    input logic [7:0] ui_in,
    input logic [7:0] uio_in,
    input logic [7:0] uio_out,
    input logic [7:0] uo_out
);

    // ---------------------------------------------------------------------
    // Type Casting of Raw Hardware Ports to Packed Structures
    // ---------------------------------------------------------------------
    pmod1_inputs_t  p1_in;
    pmod2_inputs_t  p2_in;
    pmod2_outputs_t p2_out;
    pmod3_outputs_t p3_out;

    assign p1_in  = pmod1_inputs_t'(ui_in);
    assign p2_in  = pmod2_inputs_t'(uio_in);
    assign p2_out = pmod2_outputs_t'(uio_out);
    assign p3_out = pmod3_outputs_t'(uo_out);

    // ---------------------------------------------------------------------
    // COMPILE-TIME ELABORATION CHECKS (Static Assertions)
    // ---------------------------------------------------------------------
    // Ensures that total packed sizing perfectly matches Tiny Tapeout 8-bit ports.
    // Static compile-time verification assertions checking core bit-slice scaling
    initial begin
        // Verify that the standard input structure packs down to exactly an 8-bit bus profiles
        case (1'b1)
            default: begin
                static_assert_input_width:         assert (\$bits(pmod1_inputs_t)  == 8);
                static_assert_biidir_input_width:  assert (\$bits(pmod2_inputs_t)  == 8);
                static_assert_biidir_output_width: assert (\$bits(pmod2_outputs_t) == 8);
                static_assert_output_width:        assert (\$bits(pmod3_outputs_t) == 8);
            end
        endcase
    end

    // ---------------------------------------------------------------------
    // BIT-ALIGNMENT FORMAL INVARIANTS (Proving Field Positions)
    // ---------------------------------------------------------------------

    // 1. PMOD 1 Input Mapping Verification
    assert property (p1_in.control_bits == ui_in[7:5]);
    assert property (p1_in.addr         == ui_in[4:0]);

    // 2. PMOD 2 Input Mapping Verification (Numerical pin progression verification)
    assert property (p2_in.unused_p2_b7 == uio_in[7]);
    assert property (p2_in.FLG_IN_n        == uio_in[6]);
    assert property (p2_in.uio5_pad     == uio_in[5]);
    assert property (p2_TESTMODE_n      == uio_in[4]);
    assert property (p2_in.be_n         == uio_in[3]);
    assert property (p2_in.mpd_n        == uio_in[2]);
    assert property (p2_in.ref_n        == uio_in[1]);
    assert property (p2_in.ren          == uio_in[0]);

    // 3. PMOD 2 Output Mapping Verification
    assert property (p2_out.uio7_out    == uio_out[7]);
    assert property (p2_out.uio6_out    == uio_out[6]);
    assert property (p2_out.TRIGGER_OUT == uio_out[5]);
    assert property (p2_out.uio4_out    == uio_out[4]);
    assert property (p2_out.uio3_out    == uio_out[3]);
    assert property (p2_out.uio2_out    == uio_out[2]);
    assert property (p2_out.uio1_out    == uio_out[1]);
    assert property (p2_out.uio0_out    == uio_out[0]);

    // 4. PMOD 3 Output Mapping Verification (Left-to-Right MSB to LSB packing check)
    assert property (p3_out.unused_p3_b7 == uo_out[7]);
    assert property (p3_out.FLG_n        == uo_out[6]);
    assert property (p3_out.s4_n         == uo_out[5]);
    assert property (p3_out.io_n         == uo_out[4]);
    assert property (p3_out.ci_n         == uo_out[3]);
    assert property (p3_out.os_n         == uo_out[2]);
    assert property (p3_out.basic_n      == uo_out[1]);
    assert property (p3_out.s5_n         == uo_out[0]);

endmodule
`endif