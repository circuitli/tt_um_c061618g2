# SPDX-FileCopyrightText: © 2026 Fernando / Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Timer

def pack_ui_in(addr=0, map_n=0, rd4=0, rd5=0):
    """
    Packs independent hardware parameters into the 8-bit ui_in bus.
    
    Bit allocation template (MSB -> LSB):
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
    
    Bit allocation template (MSB -> LSB):
      [7:7] : Unused (defaulting to 0)
      [6]   : loop_in
      [5]   : Unused/uio5_pad Output Lane
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

# =============================================================================
# INITIALIZATION RUNNER: Baseline Global Reset Check
# =============================================================================
@cocotb.test()
async def test_project_init(dut):
    dut._log.info("Starting Asynchronous MMU Simulation Frame...")

    # 1. Standard template initializations
    dut._log.info("[*] Checking cold power-on state...")
    dut.ena.value = 1
    dut.rst_n.value = 1  
    dut.ui_in.value = 0 
    dut.uio_in.value = 0

    # 2. Wait exactly 1 nanosecond for the logic arrays to stabilize
    await Timer(1, units="ns")
    dut._log.info("[+] Power-on initialization completed successfully.")

# =============================================================================
# TEST CASE 1: Standard Operational Mode (Manually Driving All Pins)
# =============================================================================
@cocotb.test()
async def test_standard_os_read(dut):
    dut._log.info("--- Running Test Case 1: Standard OS Read ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  
    
    # Drive all lines explicitly
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    assert (pins & (1 << 2)) == 0, f"Error: /OS failed to drop low in standard mode! Got: {bin(pins)}"
    dut._log.info("[+] Test Case 1 Passed: /OS drops low under normal conditions.")

# =============================================================================
# TEST CASE 2: Disconnected PMOD Simulation (Testing Default Pull-ups)
# =============================================================================
@cocotb.test()
async def test_disconnected_pmod_behavior(dut):
    dut._log.info("--- Running Test Case 2: Disconnected PMODs ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  

    # CRITICAL: We DO NOT drive dut.uio_in here to test the tb.v initial block!
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    assert (pins & (1 << 2)) == 0, f"Error: /OS failed to drop low with floating inputs! Got: {bin(pins)}"
    dut._log.info("[+] Test Case 2 Passed: /OS drops low using internal testbench pull-ups.")
