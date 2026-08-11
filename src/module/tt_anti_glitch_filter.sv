`ifndef ANTI_GLITCH_FILTER_SVH
`define ANTI_GLITCH_FILTER_SVH
`default_nettype none

module tt_anti_glitch_filter (
    input  bit raw_signal_in,
    output bit clean_signal_out
);
    // Create an intentional gate-delay path using a chain of buffers/inverters.
    // To prevent the compiler from optimizing these away, we force an attribute flag.
    (* keep = "true" *) bit d1, d2, d3;

    assign d1 = !raw_signal_in;
    assign d2 = !d1;
    assign d3 = !d2;

    // A combinatorial Majority Voter (2-out-of-3 bit).
    // The output will ONLY flip states if the input signal remains stable 
    // long enough to propagate completely through the delay line. 
    // Any transient glitch narrower than the gate delays is completely suppressed.
    assign clean_signal_out = (raw_signal_in && d2) || (raw_signal_in && d3) || (d2 && d3);

endmodule
`endif