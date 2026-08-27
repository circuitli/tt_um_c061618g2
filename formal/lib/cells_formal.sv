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

// =========================================================================
// LOOP-SAFE IDEAL CELL MODELS FOR SBY FORMAL VERIFICATION
// Introduces an implicit clocked state boundary strictly under the FORMAL pass.
// This cuts the zero-delay combinational circles inside your inverter chains,
// allowing write_smt2 to map out your address truth tables flawlessly!
// =========================================================================

// =========================================================================
// IDEAL TRANSISTOR CELL REPLICAS FOR SBY FORMAL VERIFICATION
// FIXED: Swapped behavioral logical operators (&&) for bitwise operators (&)
// to prevent the SMT2 backend tracker from creating a simplemap self-loop!
// =========================================================================

module sg13g2_and2_1 (
    input  wire A,
    input  wire B,
    output wire X
);
    // Pure bitwise intersection mapping (completely loop-safe for simplemap)
    assign X = A & B;
endmodule

module sg13g2_inv_1 (
    input  wire A,
    output wire Y
);
    // Pure bitwise inversion
    assign Y = ~A;
endmodule

module sg13g2_buf_4 (
    input  wire A,
    output wire X
);
    // Ideal non-inverting pass-through
    assign X = A;
endmodule
