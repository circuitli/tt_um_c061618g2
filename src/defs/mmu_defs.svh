`ifndef MMU_DEFS_SVH
`define MMU_DEFS_SVH

// Tiny Tapeout dev kit main ports

// =========================================================================
// PHYSICAL PMOD 1 INPUT STANDARD INTERFACE (ui_in)
// =========================================================================
typedef struct packed {
    logic [0:0]  rd5;      // Tracks ui_in[7] -> Cartridge Sense A000
    logic [0:0]  rd4;      // Tracks ui_in[6] -> Cartridge Sense 8000
    logic [0:0]  map_n;    // Tracks ui_in[5] -> /MAP Selftest
    //logic [4:0]  addr;     // LINT BUG: Tracks ui_in[4:0] -> Address bus slice (A15, A14, A13, A12, A11)
    logic       a15;      // Bit 4
    logic       a14;      // Bit 3
    logic       a13;      // Bit 2
    logic       a12;      // Bit 1
    logic       a11;      // Bit 0
} pmod1_inputs_t;

// =========================================================================
// PHYSICAL PMOD 2 CONTROL INPUTS STANDARD INTERFACE (uio_in)
// =========================================================================
// Traces inputs in numerical pin progression directly from Pin 1 to Pin 6:
typedef struct packed {
    logic       unused_p2_b7; // Bit 7 -> Pmod 2, Pin 8
    logic       LOOP_IN;  // Bit 6 -> uio_in -> PMOD 2 Pin 7 (Active-High System Disable Loop)
    logic       uio5_pad;  // Bit 5 -> Pmod 2, Pin 6 (Exempted; Output Lane)
    logic       FLG_n;    // Bit 4 -> uio_in -> PMOD 2 Pin 5 (Active-Low System Disable Flag)
    logic       be_n;     // Bit 3 -> uio_in -> PMOD 2 Pin 4 (/BE BASIC software enable)
    logic       mpd_n;    // Bit 2 -> uio_in -> PMOD 2 Pin 3 (/MPD Math Pack Disable)
    logic       ref_n;    // Bit 1 -> uio_in -> PMOD 2 Pin 2 (/REF DRAM Refresh)
    logic       ren;      // Bit 0 -> uio_in -> PMOD 2 Pin 1 (REN OS ROM Hardware Enable)
} pmod2_inputs_t;

// Output Tracking Bundle:
typedef struct packed {
    logic       uio7_out; // Bit 7 -> Tied Low 
    logic       uio6_out; // Bit 6 -> Tied Low
    logic       uio5_out; // Bit 5 -> Tied Low (Dedicated Input Pin Lane)
    logic       trigger_out; // Bit 4 -> uio_out -> PMOD 2 Pin 5 ACTIVE TRIGGER DIG-TAP
    logic       uio3_out; // Bit 3 -> Tied Low (Dedicated Input Pin Lane)
    logic       uio2_out; // Bit 2 -> Tied Low (Dedicated Input Pin Lane)
    logic       uio1_out; // Bit 1 -> Tied Low (Dedicated Input Pin Lane)
    logic       uio0_out; // Bit 0 -> Tied Low (Dedicated Input Pin Lane)
} pmod2_outputs_t;

// SystemVerilog packs left-to-right (MSB to LSB).
typedef struct packed {
    logic       unused_p3_b7;// Bit 7 -> Pmod 3, Pin 8 (Static 0 Ground Tie-off)
    logic       loop_out; // Bit 6 -> Pmod 3, Pin 7 (ACTIVE-HIGH SYSTEM LOOP STATUS)
    logic       s4_n;     // Bit 5 -> /S4 Right Cartridge Select
    logic       io_n;     // Bit 4 -> /IO Peripheral Select ($D000)
    logic       ci_n;     // Bit 3 -> /CI CAS Inhibit (RAM bypass flag)
    logic       os_n;     // Bit 2 -> /OS Operating System Select
    logic       basic_n;  // Bit 1 -> /BASIC Internal ROM Select
    logic       s5_n;     // Bit 0 -> /S5 Left Cartridge Select
} pmod3_outputs_t;

endif // Ensure this line is present at the very end to close the guard!