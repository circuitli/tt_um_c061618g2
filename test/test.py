# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting Asynchronous MMU Simulation...")

    #1. Standard template initializations
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.st_n.value = 1  # Keep the global frame reset high/in
    dut.ui_in.value = 0 # Safe default layout sweep
    dut.uio_in.value = 0

    # 2. Wait exactly 1 nanosecond for the gates to stabilize
    await Timer(1, units="ns")

    # 3. Overwrite immediately with a valid address test loop
    # Test an OS ROM read cycle ($F800 -> All address bits high)
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=0)

    await Timer(1, units="ns") # Allow pure gates to transition

    # Assertions to verify the outputs match your active-low truth table
    dut._log.info("Test project behavior")
    dut._log.info("Test Case 1: Checking OS ROM Banking...")
    assert dut.uo_out.value.integer & (1 << 1) == 0, "Error: /OS failed to drop low!"


   
