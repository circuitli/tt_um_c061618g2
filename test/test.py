# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
#from cocotb.clock import Clock
#from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer, RisingEdge, FallingEdge

def pack_ui_in(addr=0, map_n=0, rd4=0, rd5=0):
    """
    Packs independent hardware parameters into the 8-bit ui_in bus.
    
    Bit allocation template:
      [7]   : rd5
      [6]   : rd4
      [5]   : map_n
      [4:0] : addr (5-bit value)
    """
    return (
        ((rd5 & 0x01) << 7) |
        ((rd4 & 0x01) << 6) |
        ((map_n & 0x01) << 5) |
        (addr & 0x1F)
    )

def pack_uio_in(ren=0, ref_n=0, mpd_n=0, be_n=0, flg_n=0, loop_in=0):
    """
    Packs bidirectional interface control parameters into the 8-bit uio_in bus.
    
    Bit allocation template:
      [7:7] : Unused (defaulting to 0)
      [6]   : loop_in
      [4]   : flg_n
      [3]   : be_n
      [2]   : mpd_n
      [1]   : ref_n
      [0]   : ren
    """
    return (
        ((loop_in & 0x01) << 6) |
        ((flg_n & 0x01) << 4) |
        ((be_n & 0x01) << 3) |
        ((mpd_n & 0x01) << 2) |
        ((ref_n & 0x01) << 1) |
        (ren & 0x01)
    )

@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting Asynchronous MMU Simulation...")

    #1. Standard template initializations
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.rst_n.value = 1  # Keep the global frame reset high/in
    dut.ui_in.value = 0 # Safe default layout sweep
    dut.uio_in.value = 0

    # 2. Wait exactly 1 nanosecond for the gates to stabilize
    await Timer(1, unit="ns")

    # 3. Overwrite immediately with a valid address test loop
    # Test an OS ROM read cycle ($F800 -> All address bits high)
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(1, unit="ns") # Allow pure gates to transition

    # Convert the output to an integer for easy bit-checking
    pins = dut.uo_out.value.to_unsigned()

    print(f"--- MMU OUTPUT PINS ---")
    print(f"/S5 Left Cartridge:  {pins & (1 << 0)}")
    print(f"/BASIC ROM Select:   {(pins & (1 << 1)) >> 1}")
    print(f"/OS ROM Select:      {(pins & (1 << 2)) >> 2}")
    print(f"/CI CAS Inhibit:     {(pins & (1 << 3)) >> 3}")
    print(f"/IO Peripheral:      {(pins & (1 << 4)) >> 4}")
    print(f"/S4 Right Cartridge: {(pins & (1 << 5)) >> 5}")
    print(f"LOOP_OUT Status:     {(pins & (1 << 6)) >> 6}")

    # Assertions to verify the outputs match your active-low truth table
    dut._log.info("Test project behavior")
    dut._log.info("Test Case 1: Checking OS ROM Banking...")
    assert (pins & (1 << 2)) == 0, "Error: /OS failed to drop low!"


   
