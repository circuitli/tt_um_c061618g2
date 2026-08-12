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

module mmu_defs_formal;
    // Import the shared package namespace to validate properties
    //import mmu_defs::*;

    // Static compile-time verification assertions checking core bit-slice scaling
    initial begin
        // Verify that the standard input structure packs down to exactly an 8-bit bus profiles
        case (1'b1)
            default: begin
                static_assert_input_width:  assert (\$bits(pmod1_inputs_t)  == 8);
                static_assert_output_width: assert (\$bits(pmod3_outputs_t) == 8);
            end
        endcase
    end
endmodule

`endif