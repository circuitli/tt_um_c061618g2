// ==============================================================================
// SECTION: TOP-LEVEL HARDWARE WRAPPER CONSTRAINTS
// ==============================================================================
`default_nettype none
`include "src/defs/mmu_defs.sv"
`include "src/core/mmu_core.sv"
`include "src/module/tt_anti_glitch_filter.sv"

// 1. Import everything from the package namespace
//import mmu_defs::*;

module tt_um_c061618g2 (
    input  [7:0] ui_in,    // Dedicated hardware inputs
    output [7:0] uo_out,   // Dedicated hardware outputs
    input  [7:0] uio_in,   // Bidirectional bus input network
    output [7:0] uio_out,  // Bidirectional bus output network
    output [7:0] uio_oe,   // Bidirectional three-state direction gates
    /* verilator lint_off UNUSEDSIGNAL */
    input  [0:0] ena,      // Leave this here! The compiler requires it.
    input  [0:0] clk,      // Part of the strict wrapper standard!
    input  [0:0] rst_n     // Part of the strict wrapper standard!
    /* verilator lint_on UNUSEDSIGNAL */
);

    // =========================================================================
    // SEPARATED INTERFACE STRUCTURE BINDING
    // =========================================================================
    pmod1_inputs_t  pmod1_bus;
    pmod2_inputs_t  pmod2_in_bus;
    pmod2_outputs_t pmod2_out_bus;
    pmod3_outputs_t pmod3_bus;

    // Map input vectors cleanly index-for-index
    assign pmod1_bus    = ui_in;
    assign pmod2_in_bus = uio_in;
    
    // ---- SUB-SECTION: BUS DIRECTION HARDCODING ----
    assign uio_oe = 8'b00100000; 

    /* verilator lint_off UNUSED */
    wire unused_p2_b7 = pmod2_in_bus[7]; // Bit 7 -> Pmod 2, Pin 8
    wire uio5_pad     = pmod2_in_bus[5];  // Bit 5 -> Pmod 2, Pin 6 (Exempted; Output Lane)
    /* verilator lint_on UNUSED */

    // =========================================================================
    // CORE SELECTIONS & DECODING PASS
    // =========================================================================
    pmod3_outputs_t core_signals;
    bit         stabilized_ci_n;

    // 1. Process Core Decoding Matrix
    mmu_core core_inst (
        .core_in  (pmod1_bus),
        .ren      (pmod2_in_bus.ren),
        .ref_n    (pmod2_in_bus.ref_n),
        .mpd_n    (pmod2_in_bus.mpd_n),
        .be_n     (pmod2_in_bus.be_n), 
        .core_out (core_signals)
    );

     // 2. Clear RAM toggles via the delay filter circuit
    tt_anti_glitch_filter filter_inst (
        .raw_signal_in    (core_signals.ci_n),
        .clean_signal_out (stabilized_ci_n)
    );

    // Evaluate master system override control flags
    bit system_disabled;
    assign system_disabled = (pmod2_in_bus.FLG_n == 1'b0) || (pmod2_in_bus.LOOP_IN == 1'b0);

    // Move the selection outside into a continuous assignment
    wire a11 = pmod1_bus.addr[0]; 

    // To bypass Yosys limitations with procedural assignments to individual 
    // packed struct members, intermediate flat bit signals are declared.  
    /* verilator lint_off UNUSED */
    wire unused_p3_b7 = core_signals.unused_p3_b7;
    wire LOOP_OUT     = core_signals.LOOP_OUT;
    /* verilator lint_on UNUSED */
    bit pmod3_s4_n = core_signals.s4_n;
    bit pmod3_io_n = core_signals.io_n;
    bit pmod3_os_n = core_signals.os_n;
    bit pmod3_basic_n = core_signals.basic_n;
    bit pmod3_s5_n    = core_signals.s5_n;

    // =========================================================================
    // COMBINATORIAL ROUTING MATRIX
    // =========================================================================
    always_comb begin
        // --- Pmod 2 Outputs Mapping ---
        pmod2_out_bus = '0; 
        
        // Explicitly loop out A11
        pmod2_out_bus.TRIGGER_OUT = a11; 

        // --- Pmod 3 Outputs Mapping ---
        if (system_disabled) begin
            pmod3_bus.unused_p3_b7 = 1'b0;
            pmod3_bus.LOOP_OUT  = 1'b1; 
            pmod3_bus.s4_n      = 1'b1;
            pmod3_bus.io_n      = 1'b1;
            pmod3_bus.ci_n      = 1'b1;
            pmod3_bus.os_n      = 1'b1;
            pmod3_bus.basic_n   = 1'b1;
            pmod3_bus.s5_n      = 1'b1;
        end else begin
            pmod3_bus.unused_p3_b7 = 1'b0;                 
            pmod3_bus.LOOP_OUT  = 1'b0;                 
            pmod3_bus.s4_n      = pmod3_s4_n; 
            pmod3_bus.io_n      = pmod3_io_n;    
            pmod3_bus.ci_n      = stabilized_ci_n;  
            pmod3_bus.os_n      = pmod3_os_n;
            pmod3_bus.basic_n   = pmod3_basic_n;
            pmod3_bus.s5_n      = pmod3_s5_n;
        end
    end

    // Direct hardware driver block copies (Zero indices used)
    assign uio_out = pmod2_out_bus;
    assign uo_out  = pmod3_bus;

endmodule