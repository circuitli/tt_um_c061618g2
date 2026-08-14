`default_nettype none
`timescale 1ns / 1ps

// ==============================================================================
//  Cloud PDK Library Resolution (Bypasses hardcoded Tiny Tapeout script limits)
// ==============================================================================
`ifdef GL_TEST
    // Step out of the test folder, look inside your isolated drop folder, 
    // and grab the pristine monolithic IHP cell library directly!
    `include "../gds_drop/ihp-sg13g2/libs.ref/sg13g2/verilog/sg13g2.v"
`endif

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);

    // Do NOT place a fixed delay line here! 
    // Leaving it open lets the logging engine track your pins 
    // for the full duration of your test.py execution loops.
    //#1;
  end

  // Testbench signals matching the standard Tiny Tapeout interface layout
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // =========================================================================
  // INITIAL BASELINE DRIVERS
  // =========================================================================
  initial begin
      // Set up the safe baseline environment states
      uio_in = 8'hFF;   // All bidirectionals high to drop system_disabled to 0
      ui_in  = 8'h00;   // Baseline address lines grounded to $0000
  end

 /*
`ifdef GL_TEST
  // Supply rails required strictly for gate-level netlist simulations
  supply1 VPWR;
  supply0 VGND;
`endif
 */

  // Instantiate the actual user module under test (UUT)
  tt_um_c061618g2 user_project (
 /*
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
 */
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // Bidirectional IOs: Input path
      .uio_out(uio_out),  // Bidirectional IOs: Output path
      .uio_oe (uio_oe),   // Bidirectional IOs: Output Enable path (active high)
      .ena    (ena),      // Design enable signal (always high when selected)
      .clk    (clk),      // Global clock signal
      .rst_n  (rst_n)     // Global active-low asynchronous reset
  );

endmodule
