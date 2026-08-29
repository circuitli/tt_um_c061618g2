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

`ifndef MMU_DEFS_SVH
`define MMU_DEFS_SVH
`default_nettype none

// =========================================================================
// PHYSICAL PMOD 1 INPUT STANDARD INTERFACE (ui_in)
// =========================================================================
typedef struct packed {
    logic [2:0] control_bits; // Combines rd5, rd4, and map_n into a 3-bit vector
    logic [4:0] addr;         // Tracks ui_in[4:0] -> Address bus slice (A15-A11)
} pmod1_inputs_t;

// =========================================================================
// PHYSICAL PMOD 2 CONTROL INPUTS STANDARD INTERFACE (uio_in)
// =========================================================================
typedef struct packed {
    /* verilator lint_off UNUSEDSIGNAL */
    logic       unused_p2_b7; // Bit 7 -> Pmod 2, Pin 8 - Reserved
    /* verilator lint_on UNUSEDSIGNAL */
    logic       FLG_IN_n;     // Bit 6 -> uio_in[6] -> PMOD 2 Pin 7 (Active-Low Disable Flag)
    /* verilator lint_off UNUSEDSIGNAL */
    logic       uio5_pad;     // Bit 5 -> Pmod 2, Pin 6 (Exempted; Output Lane)
    /* verilator lint_on UNUSEDSIGNAL */
    /* verilator lint_off UNUSEDSIGNAL */ 
    logic       TESTMODE_n;   // Bit 4 -> uio_in[4] -> PMOD 2 Pin 5 (Active-Low test mode bypass) 
    /* verilator lint_on UNUSEDSIGNAL */
    logic       be_n;         // Bit 3 -> uio_in[3] -> PMOD 2 Pin 4 (/BE BASIC enable)
    logic       mpd_n;        // Bit 2 -> uio_in[2] -> PMOD 2 Pin 3 (/MPD Math Pack Disable)
    logic       ref_n;        // Bit 1 -> uio_in[1] -> PMOD 2 Pin 2 (/REF DRAM Refresh)
    logic       ren;          // Bit 0 -> uio_in[0] -> PMOD 2 Pin 1 (REN OS ROM Enable)
} pmod2_inputs_t;

// =========================================================================
// PHYSICAL PMOD 2 CONTROL OUTPUTS STANDARD INTERFACE (uio_out)
// =========================================================================
typedef struct packed {
    /* verilator lint_off UNUSEDSIGNAL */
    logic       uio7_out; // Bit 7 -> Tied Low (Reserved)
    logic       uio6_out; // Bit 6 -> Tied Low (Dedicated Input Pin Lane)
    /* verilator lint_on UNUSEDSIGNAL */
    logic       TRIGGER_OUT; // Bit 5 -> uio_out[5] -> PMOD 2 Pin 5 ACTIVE TRIGGER
    /* verilator lint_off UNUSEDSIGNAL */
    logic       uio4_out; // Bit 4 -> Tied Low (Dedicated Input Pin Lane)
    logic       uio3_out; // Bit 3 -> Tied Low (Dedicated Input Pin Lane)
    logic       uio2_out; // Bit 2 -> Tied Low (Dedicated Input Pin Lane)
    logic       uio1_out; // Bit 1 -> Tied Low (Dedicated Input Pin Lane)
    logic       uio0_out; // Bit 0 -> Tied Low (Dedicated Input Pin Lane)
    /* verilator lint_on UNUSEDSIGNAL */
} pmod2_outputs_t;

// =========================================================================
// PHYSICAL PMOD 3 OUTPUT INTERFACE (uo_out)
// =========================================================================
typedef struct packed {
    logic       unused_p3_b7;// Bit 7 -> Pmod 3, Pin 8 (Static 0 Ground Tie-off)
    logic       FLG_n;       // Bit 6 -> Pmod 3, Pin 7 (Active-Low chip fault)
    logic       s4_n;        // Bit 5 -> /S4 Right Cartridge Select
    logic       io_n;        // Bit 4 -> /IO Peripheral Select ($D000)
    logic       ci_n;        // Bit 3 -> /CI CAS Inhibit (RAM bypass flag)
    logic       os_n;        // Bit 2 -> /OS Operating System Select
    logic       basic_n;     // Bit 1 -> /BASIC Internal ROM Select
    logic       s5_n;        // Bit 0 -> /S5 Left Cartridge Select
} pmod3_outputs_t;

`default_nettype wire
`endif // MMU_DEFS_SVH
