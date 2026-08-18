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
 
`ifndef MMU_DEFS_SVH
`define MMU_DEFS_SVH

// Tiny Tapeout dev kit main ports
//package mmu_defs;

// 1. Explicitly define a custom 5-bit vector type to bypass the struct bracket bug
//typedef bit [4:0] addr_t;

// =========================================================================
// PHYSICAL PMOD 1 INPUT STANDARD INTERFACE (ui_in)
// =========================================================================
typedef struct packed {
    bit [2:0] control_bits; // Combines rd5, rd4, and map_n into a 3-bit vector
    //bit rd5;      // Tracks ui_in[7] -> Cartridge Sense A000
    //bit rd4;      // Tracks ui_in[6] -> Cartridge Sense 8000
    //bit map_n;    // Tracks ui_in[5] -> /MAP Selftest
    bit [4:0] addr; // Tracks ui_in[4:0] -> Address bus slice (A15, A14, A13, A12, A11)
    //addr_t addr;     // Tracks ui_in[4:0] -> Address bus slice (A15, A14, A13, A12, A11)
    //bit       a15;      // Bit 4
    //bit       a14;      // Bit 3
    //bit       a13;      // Bit 2
    //bit       a12;      // Bit 1
    //bit       a11;      // Bit 0
} pmod1_inputs_t;

// =========================================================================
// PHYSICAL PMOD 2 CONTROL INPUTS STANDARD INTERFACE (uio_in)
// =========================================================================
// Traces inputs in numerical pin progression directly from Pin 1 to Pin 6:
typedef struct packed {
    /* verilator lint_off UNUSEDSIGNAL */
    bit       unused_p2_b7; // Bit 7 -> Pmod 2, Pin 8
    /* verilator lint_on UNUSEDSIGNAL */
    bit       FLG_n;    // Bit 6 -> uio_in -> PMOD 2 Pin 7 (Active-Low System Disable Flag)
    /* verilator lint_off UNUSEDSIGNAL */
    bit       uio5_pad;  // Bit 5 -> Pmod 2, Pin 6 (Exempted; Output Lane)
    /* verilator lint_on UNUSEDSIGNAL */
    bit       TESTMODE_n; // Bit 4 -> uio_in[4] -> PMOD 2 Pin 7 (Active-Low production test mode bypass)
    bit       be_n;     // Bit 3 -> uio_in -> PMOD 2 Pin 4 (/BE BASIC software enable)
    bit       mpd_n;    // Bit 2 -> uio_in -> PMOD 2 Pin 3 (/MPD Math Pack Disable)
    bit       ref_n;    // Bit 1 -> uio_in -> PMOD 2 Pin 2 (/REF DRAM Refresh)
    bit       ren;      // Bit 0 -> uio_in -> PMOD 2 Pin 1 (REN OS ROM Hardware Enable)
} pmod2_inputs_t;

// Output Tracking Bundle:
typedef struct packed {
    /* verilator lint_off UNUSEDSIGNAL */
    bit       uio7_out; // Bit 7 -> Tied Low 
    bit       uio6_out; // Bit 6 -> Tied Low
    /* verilator lint_on UNUSEDSIGNAL */
    bit       TRIGGER_OUT; // Bit 5 -> uio_out -> PMOD 2 Pin 5 ACTIVE TRIGGER DIG-TAP
    /* verilator lint_off UNUSEDSIGNAL */
    bit       uio4_out; // Bit 4 -> Tied Low (Dedicated Input Pin Lane)
    bit       uio3_out; // Bit 3 -> Tied Low (Dedicated Input Pin Lane)
    bit       uio2_out; // Bit 2 -> Tied Low (Dedicated Input Pin Lane)
    bit       uio1_out; // Bit 1 -> Tied Low (Dedicated Input Pin Lane)
    bit       uio0_out; // Bit 0 -> Tied Low (Dedicated Input Pin Lane)
    /* verilator lint_on UNUSEDSIGNAL */
} pmod2_outputs_t;

// SystemVerilog packs left-to-right (MSB to LSB).
typedef struct packed {
    bit       unused_p3_b7;// Bit 7 -> Pmod 3, Pin 8 (Static 0 Ground Tie-off)
    bit       LOOP_OUT; // Bit 6 -> Pmod 3, Pin 7 (ACTIVE-HIGH SYSTEM LOOP STATUS)
    bit       s4_n;     // Bit 5 -> /S4 Right Cartridge Select
    bit       io_n;     // Bit 4 -> /IO Peripheral Select ($D000)
    bit       ci_n;     // Bit 3 -> /CI CAS Inhibit (RAM bypass flag)
    bit       os_n;     // Bit 2 -> /OS Operating System Select
    bit       basic_n;  // Bit 1 -> /BASIC Internal ROM Select
    bit       s5_n;     // Bit 0 -> /S5 Left Cartridge Select
} pmod3_outputs_t;

//endpackage

`endif // Ensure this line is present at the very end to close the guard!