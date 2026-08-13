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
# TEST CASE 1: INITIALIZATION RUNNER: Baseline Global Reset Check
# =============================================================================
@cocotb.test()
async def test_project_init(dut):
    dut._log.info("Starting Asynchronous MMU Simulation Frame...")

    # 1. Standard template initializations
    dut._log.info("[*] Checking cold power-on state...")
    dut.ena.value = 1
    dut.rst_n.value = 1  
    
    # FIX: Do NOT force hard 0 onto the buses here. 
    # Let cocotb yield directly to your testbench initial pull-up models instead.

    # 2. Wait exactly 1 nanosecond for the logic arrays to stabilize
    await Timer(1, units="ns")
    dut._log.info("[+] Power-on initialization completed successfully.")


# =============================================================================
# TEST CASE 2: Disconnected PMOD Simulation (Testing Default Pull-ups & Separation)
# =============================================================================
@cocotb.test()
async def test_disconnected_pmod_behavior(dut):
    dut._log.info("--- Running Test Case 2: Disconnected PMODs ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  

    # Address 0x1F maps successfully to your target constraint (a >= 5'h1C)
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    # Extract structural bit slices matching pmod3_outputs_t
    s5_pin    = (pins & (1 << 0)) >> 0
    basic_pin = (pins & (1 << 1)) >> 1
    os_pin    = (pins & (1 << 2)) >> 2
    io_pin    = (pins & (1 << 4)) >> 4
    s4_pin    = (pins & (1 << 5)) >> 5
    
    dut._log.info(f"[*] Floating Test Matrix -> /OS: {os_pin}, /BASIC: {basic_pin}, /IO: {io_pin}")
    
    # Exhaustive Checks: OS must be enabled (0), EVERY other select must be disabled (1)
    assert os_pin == 0, f"[!] Failure: /OS failed to drop low with floating inputs! Got: {os_pin}"
    assert basic_pin == 1, f"[!] Failure: /BASIC bled into OS territory with floating inputs! Got: {basic_pin}"
    assert io_pin == 1, f"[!] Failure: /IO bled into OS territory with floating inputs! Got: {io_pin}"
    assert s4_pin == 1, f"[!] Failure: /S4 active-low select bled with floating inputs! Got: {s4_pin}"
    assert s5_pin == 1, f"[!] Failure: /S5 active-low select bled with floating inputs! Got: {s5_pin}"
    
    dut._log.info("[+] Test Case 2 Passed: /OS drops low and other selections stay safely disabled.")

# =============================================================================
# TEST CASE 3: Standard Operational Mode (Targeting OS Kernel Area $F800)
# =============================================================================
@cocotb.test()
async def test_standard_os_read(dut):
    dut._log.info("--- Running Test Case 3: Standard OS Read ($F800) ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  
    
    # 0x1F is inside the strict OS range (5'h1C - 5'h1F)
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    s5_pin    = (pins & (1 << 0)) >> 0
    basic_pin = (pins & (1 << 1)) >> 1
    os_pin    = (pins & (1 << 2)) >> 2
    io_pin    = (pins & (1 << 4)) >> 4
    s4_pin    = (pins & (1 << 5)) >> 5
    
    dut._log.info(f"[*] Driven OS Matrix -> /OS: {os_pin}, /BASIC: {basic_pin}, /IO: {io_pin}")
    
    # Exhaustive Checks: OS must be enabled (0), EVERY other select must be disabled (1)
    assert os_pin == 0, f"[!] Failure: /OS stayed high (1) in OS territory! Got: {os_pin}"
    assert basic_pin == 1, f"[!] Failure: /BASIC bled over into OS territory! Got: {basic_pin}"
    assert io_pin == 1, f"[!] Failure: /IO bled over into OS territory! Got: {io_pin}"
    assert s4_pin == 1, f"[!] Failure: /S4 bank bled over into OS territory! Got: {s4_pin}"
    assert s5_pin == 1, f"[!] Failure: /S5 bank bled over into OS territory! Got: {s5_pin}"
    
    dut._log.info("[+] Test Case 3 Passed: OS territory safely isolated from all other subsystems.")

# =============================================================================
# TEST CASE 4: Targeting BASIC Interpreter Area ($A000)
# =============================================================================
@cocotb.test()
async def test_standard_basic_read(dut):
    dut._log.info("--- Running Test Case 4: Standard BASIC Read ($A000) ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  

    # 0x14 is inside the strict BASIC range (5'h14 - 5'h17)
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    s5_pin    = (pins & (1 << 0)) >> 0
    basic_pin = (pins & (1 << 1)) >> 1
    os_pin    = (pins & (1 << 2)) >> 2
    io_pin    = (pins & (1 << 4)) >> 4
    s4_pin    = (pins & (1 << 5)) >> 5
    
    dut._log.info(f"[*] Driven BASIC Matrix -> /BASIC: {basic_pin}, /OS: {os_pin}, /IO: {io_pin}")
    
    # Exhaustive Checks: BASIC must be enabled (0), EVERY other select must be disabled (1)
    assert basic_pin == 0, f"[!] Failure: /BASIC stayed high (1) in BASIC territory! Got: {basic_pin}"
    assert os_pin == 1, f"[!] Failure: /OS bled down into BASIC territory! Got: {os_pin}"
    assert io_pin == 1, f"[!] Failure: /IO bled down into BASIC territory! Got: {io_pin}"
    assert s4_pin == 1, f"[!] Failure: /S4 bank bled down into BASIC territory! Got: {s4_pin}"
    assert s5_pin == 1, f"[!] Failure: /S5 bank bled down into BASIC territory! Got: {s5_pin}"
    
    dut._log.info("[+] Test Case 4 Passed: BASIC territory safely isolated from all other subsystems.")

# =============================================================================
# TEST CASE 5: Targeting Peripheral Hardware I/O Space ($D000)
# =============================================================================
@cocotb.test()
async def test_standard_io_read(dut):
    dut._log.info("--- Running Test Case 5: Standard I/O Read ($D000) ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  

    # Address 5'b11010 = 0x1A maps exactly to the $D000 Hardware I/O block
    dut.ui_in.value = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    s5_pin    = pins & 0x01
    basic_pin = (pins >> 1) & 0x01
    os_pin    = (pins >> 2) & 0x01
    ci_pin    = (pins >> 3) & 0x01
    io_pin    = (pins >> 4) & 0x01
    s4_pin    = (pins >> 5) & 0x01
    
    assert io_pin == 0, f"[!] Failure: /IO peripheral line failed to drop low at $D000!"
    assert os_pin == 1, f"[!] Failure: /OS bled down into I/O territory!"
    assert basic_pin == 1, f"[!] Failure: /BASIC bled down into I/O territory!"
    assert s4_pin == 1, f"[!] Failure: /S4 bled down into I/O territory!"
    assert s5_pin == 1, f"[!] Failure: /S5 bled down into I/O territory!"
    dut._log.info("[+] Pass: Hardware I/O page decoded and verified successfully.")

# =============================================================================
# TEST CASE 6: Checking Right Cartridge Expansion Bank Control (/S4)
# =============================================================================
@cocotb.test()
async def test_s4_bank_select(dut):
    dut._log.info("--- Running Test Case 6: Checking /S4 Selection ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  

    # Address 5'b01000 = 0x08 combined with mpd_n active high and rd4 active high
    dut.ui_in.value = pack_ui_in(addr=0x08, map_n=1, rd4=1, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    s4_pin = (pins >> 5) & 0x01
    assert s4_pin == 0, f"[!] Failure: Right Expansion bank select /S4 failed to drop low!"
    dut._log.info("[+] Pass: Right expansion cartridge bank decoded and verified successfully.")

# =============================================================================
# TEST CASE 7: Checking Left Cartridge Expansion Bank Control (/S5)
# =============================================================================
@cocotb.test()
async def test_s5_bank_select(dut):
    dut._log.info("--- Running Test Case 7: Checking /S5 Selection ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  

    # Address 5'b10100 = 0x14 combined with be_n active high and rd5 active high
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    s5_pin = pins & 0x01
    assert s5_pin == 0, f"[!] Failure: Left Expansion bank select /S5 failed to drop low!"
    dut._log.info("[+] Pass: Left expansion cartridge bank decoded and verified successfully.")

# =============================================================================
# TEST CASE 8: Verifying Clock Inhibit / DRAM Refresh Wait State Generation (/CI)
# =============================================================================
@cocotb.test()
async def test_cas_inhibit_activation(dut):
    dut._log.info("--- Running Test Case 8: Checking /CI Wait State Logic ---")
    dut.ena.value = 1
    dut.rst_n.value = 1  

    # Target Address 0x1A ($D000) while ref_n drops low to trigger refresh loops
    dut.ui_in.value = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, flg_n=1, loop_in=1)

    await Timer(10, units="ns") 
    pins = dut.uo_out.value.to_unsigned()
    
    ci_pin = (pins >> 3) & 0x01
    assert ci_pin == 0, f"[!] Failure: CAS Inhibit /CI line failed to assert low during DRAM refresh cycle!"
    dut._log.info("[+] Pass: Dynamic wait state clock inhibition logic verified successfully.")
