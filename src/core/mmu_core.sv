`default_nettype none
//include "defs/mmu_defs.sv"

module mmu_core (
    input  pmod1_inputs_t  core_in, 
    input             ren,
    input             ref_n,
    input             mpd_n,
    input             be_n,
    output pmod3_outputs_t core_out  // Directly maps to the 8-bit output profile!
);
    
    // 1. Import everything from the package namespace
    import mmu_defs::*;

    // Unpack the control bits internally from the incoming structured bus
    bit rd5;
    bit rd4;
    bit map_n;
    bit [4:0] a;

    assign rd5   = core_in.control_bits[2];
    assign rd4   = core_in.control_bits[1];
    assign map_n = core_in.control_bits[0];
    assign a     = core_in.addr;

    // =========================================================================
    // ATARI MMU COMBINATORIAL DECODING EQUATIONS
    // =========================================================================
    always_comb begin
        // Clear the entire output structure to a safe default state
        core_out = '0;

        // --- ROM / RAM Chip Select Logic Equations ---
        // BASIC ROM Selection: Maps to $A000-$BFFF if BASIC is enabled
        core_out.basic_n = !(!map_n && (a >= 5'b10100) && (a <= 5'b10111) && ren);

        // OS ROM Selection: Maps to $D800-$FFFF (excluding hardware registers)
        core_out.os_n    = !((a >= 5'b11011) && ren);

        // HARDWARE CS (I/O) Selection: Maps to $D000-$D7FF area
        core_out.io_n    = !((a == 5'b11010) && ren);

        // --- RAM Bank Selection Lines ---
        core_out.s4_n    = !((a == 5'b01000) && mpd_n); 
        core_out.s5_n    = !((a == 5'b10100) && be_n);  

        // --- Dynamic Clock Inhibit / Wait State Request ---
        // Assert CI low if accessing the slow peripheral mapping matrices
        if ((a == 5'b11010) && !ref_n) begin
            core_out.ci_n = 1'b0; 
        end else begin
            core_out.ci_n = 1'b1; 
        end
    end
endmodule