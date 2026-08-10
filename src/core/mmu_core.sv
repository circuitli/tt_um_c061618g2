default_nettype none
include "defs/mmu_defs.svh"

// Core
module mmu_core (
    input  pmod1_inputs_t  core_in, 
    input  logic           ren,
    input  logic           ref_n,
    input  logic           mpd_n,
    input  logic           be_n,
    output pmod3_outputs_t core_out  // Directly maps to the 8-bit output profile!
);
    always_comb begin
        // Secure unmapped high-side lanes safely to default states
        core_out.unused_p8 = 1'b0;
        core_out.loop_out  = 1'b1; // Default to 1 to assert fail-safe loop health!

        // Asynchronous structural decoder space flags matching the internal 5-bit bus vector
        logic space_8000_9fff = (core_in.addr == 5'b10000); 
        logic space_a000_bfff = (core_in.addr == 5'b10101);  
        logic space_c000_cfff = (core_in.addr == 5'b11000);
        logic space_d000_d7ff = (core_in.addr == 5'b11010); 
        logic space_d800_dfff = (core_in.addr == 5'b11011); 
        logic space_e000_ffff = (core_in.addr == 5'b11111 || core_in.addr == 5'b11110 || core_in.addr == 5'b11101 || core_in.addr == 5'b11100);

        // Core address space mappings
        core_out.s5_n    = !(space_a000_bfff && core_in.rd5);
        core_out.basic_n = !(space_a000_bfff && !be_n && !core_in.rd5);
        core_out.io_n    = !space_d000_d7ff;

        // OS ROM mapping: blocks math pack range if external PBI MPD_N drops low
        logic os_low_match  = (space_c000_cfff && !core_in.map_n);
        logic os_math_match = (space_d800_dfff && mpd_n); 
        logic os_high_match = (space_e000_ffff && ren);
        core_out.os_n    = !(os_low_match || os_math_match || os_high_match);

        core_out.s4_n    = !(space_8000_9fff && core_in.rd4);

        // Core master CAS Inhibit computation (Bypassed instantly if ANTIC asserts refresh)
        logic raw_ci_assert = !core_out.s4_n || !core_out.s5_n || !core_out.basic_n || !core_out.io_n || !core_out.os_n;
        core_out.ci_n    = !(raw_ci_assert && ref_n);
    end
endmodule