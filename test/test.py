# Copyright 2026 circuitli (https://github.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://apache.org
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ==============================================================================
# PRODUCTION VERIFICATION SUITE MMU
# Validates: Foundational Boot, Standard Mappings, and Exceptions
# ==============================================================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, ClockCycles, NextTimeStep

def pack_ui_in(addr, map_n, rd4, rd5):
    """
    Packs scalar control lines and address slices into an 8-bit vector.
    Mapping:
      ui_in[4:0] -> addr[4:0] (Address lines A15 down to A11)
      ui_in[5]   -> map_n
      ui_in[6]   -> rd4 (Active-High)
      ui_in[7]   -> rd5 (Active-High)
    """
    vector = 0
    vector |= (addr & 0x1F)
    vector |= ((map_n & 1) << 5)
    vector |= ((rd4 & 1) << 6)
    vector |= ((rd5 & 1) << 7)
    return vector

def pack_uio_in(ren, ref_n, mpd_n, be_n, TESTMODE_n=1, FLG_IN_n=1):
    """
    Packs bidirectional bus controls into an 8-bit input vector.
    Mapping:
      uio_in[0] -> ren (Active-High ROM Enable)
      uio_in[1] -> ref_n (Active-Low Refresh Flag)
      uio_in[2] -> mpd_n
      uio_in[3] -> be_n (Active-Low BASIC Enable)
      uio_in[4] -> TESTMODE_n (Active-Low Production Test Mode)
      uio_in[6] -> FLG_IN_n (Active-Low System Disable Flag)
    """
    vector = 0
    vector |= (ren & 1) << 0
    vector |= (ref_n & 1) << 1
    vector |= (mpd_n & 1) << 2
    vector |= (be_n & 1) << 3
    vector |= (TESTMODE_n & 1) << 4
    vector |= (FLG_IN_n & 1) << 6
    return vector

def unpack_uo_out(val):
    """
    Unpacks the 8-bit hardware output vector into readable key names.
    """
    return {
        "s5_n":     (val >> 0) & 1,
        "basic_n":  (val >> 1) & 1,
        "os_n":     (val >> 2) & 1,
        "ci_n":     (val >> 3) & 1,
        "io_n":     (val >> 4) & 1,
        "s4_n":     (val >> 5) & 1,
        "FLG_n":    (val >> 6) & 1,
        "bit7":     (val >> 7) & 1
    }

async def initialize_dut(dut):
    """
    Spawns the simulation clock tree and issues a clean synchronous reset pulse.
    Dynamically scales wait states to flush internal synchronizer pipelines.
    """
    mystic_clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(mystic_clock.start())
    
    dut.ena.value = 1
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    dut.rst_n.value = 1
    
    try:
        stages = int(dut.user_project.u_clock_sync.STAGES.value)
    except AttributeError:
        stages = 2
        
    await ClockCycles(dut.clk, stages + 2)

# ==============================================================================
# CATEGORY A: FOUNDATIONAL BOOT & INITIALIZATION TASKS
# ==============================================================================

@cocotb.test()
async def test_project_init(dut):
    dut._log.info("--- Running Test Case 1: Subsystem Cold Boot Sequence ---")
    await initialize_dut(dut)
    await ReadOnly()
    dut._log.info("[+] Core clock tree and reset pipeline initialized successfully.")

# ==============================================================================
# CATEGORY B: NOMINAL ADDRESS SPACE MEMORY DECODING
# ==============================================================================

@cocotb.test()
async def test_standard_os_read(dut):
    dut._log.info("--- Running Test Case 2: Operating System ROM Decode ($F800) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 0, f"Error: /OS failed to pull active low! Got: {pins['os_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["ci_n"] == 0, "Error: /CI must fall low during active internal ROM matches!"

@cocotb.test()
async def test_standard_basic_read(dut):
    dut._log.info("--- Running Test Case 3: BASIC Interpreter Space Decode ($A000) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=0, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["basic_n"] == 0, f"Error: /BASIC failed to pull active low! Got: {pins['basic_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["os_n"] == 1, "Mutual Contention Error: /OS clapped active simultaneously!"

@cocotb.test()
async def test_standard_io_read(dut):
    dut._log.info("--- Running Test Case 4: Peripheral Hardware I/O Allocation ($D000) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["io_n"] == 0, f"Error: /IO failed to pull active low! Got: {pins['io_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["os_n"] == 1, "Collision Error: /OS activated over the hardware I/O registry!"

# ==============================================================================
# CATEGORY C: CARTRIDGE EXPANSION BANK RECOGNITION
# ==============================================================================

@cocotb.test()
async def test_s4_bank_select(dut):
    dut._log.info("--- Running Test Case 5: Right Expansion Cartridge Bank Select ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x10, map_n=1, rd4=1, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["s4_n"] == 0, f"Error: /S4 failed to pull active low! Got: {pins['s4_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["s5_n"] == 1, "Mutual Contention Error: /S5 clapped active simultaneously!"

@cocotb.test()
async def test_s5_bank_select(dut):
    dut._log.info("--- Running Test Case 6: Left Expansion Cartridge Bank Select ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["s5_n"] == 0, f"Error: /S5 failed to pull active low! Got: {pins['s5_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["s4_n"] == 1, "Mutual Contention Error: /S4 clapped active simultaneously!"

# ==============================================================================
# CATEGORY D: INTERFACE FAULT & HARDWARE SIGNAL EXCEPTIONS
# ==============================================================================

@cocotb.test()
async def test_disconnected_pmod_behavior(dut):
    dut._log.info("--- Running Test Case 7: Disconnected Peripheral Float State ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = 0xFF
    dut.uio_in.value = 0xFF
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 0, f"Error: /OS should activate at floating reset vectors! Got: {pins['os_n']}"
    assert pins["basic_n"] == 1, "Error: /BASIC leaked low during disconnected state!"
    assert pins["io_n"] == 1, "Error: /IO leaked low during disconnected state!"
    assert pins["s4_n"] == 1, "Error: /S4 leaked low during disconnected state!"
    assert pins["s5_n"] == 1, "Error: /S5 leaked low during disconnected state!"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["ci_n"] == 0, f"Error: /CI must default active-low to inhibit RAM! Got: {pins['ci_n']}"

@cocotb.test()
async def test_cas_inhibit_activation(dut):
    dut._log.info("--- Running Test Case 8: Refresh Wait-State CAS Inhibit ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["ci_n"] == 0, f"Error: CAS Inhibit failed to assert low during active refresh requests! Got: {pins['ci_n']}"

@cocotb.test()
async def test_trigger_out_passthrough_fixed(dut):
    dut._log.info("--- Running Fixed Test Case 9: TRIGGER_OUT A11 Passthrough ---")
    await initialize_dut(dut)
    dut.rst_n.value = 1
    
    # 1. Drive initial address tracking bit A11 to 0
    dut.ui_in.value = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    
    # Settle the anti-glitch filter blocks post-initialization
    await ClockCycles(dut.clk, 5)
    await ReadOnly()
    
    pins_uo = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    # FIX: Read Bit 5 of uio_out directly to evaluate TRIGGER_OUT
    trigger_out_initial = (dut.uio_out.value >> 5) & 1
    
    assert pins_uo["FLG_n"] == 1, f"Error: FLG_n failed to settle at 1! Got: {pins_uo['FLG_n']}"
    assert trigger_out_initial == 0, f"Error: TRIGGER_OUT should track initial addr 0! Got: {trigger_out_initial}"
    
    # 2. Toggle the address bit to 1
    await NextTimeStep()
    dut._log.info("Toggling address bit to 1 to verify INSTANT combinational passthrough...")
    dut.ui_in.value = pack_ui_in(addr=0x01, map_n=1, rd4=0, rd5=0)
    
    # 3. Check after exactly 1 clock cycle to prove it bypasses all delay paths
    await ClockCycles(dut.clk, 1)
    await ReadOnly() 
    
    pins_uo_after = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    # FIX: Read Bit 5 of uio_out directly again
    trigger_out_after = (dut.uio_out.value >> 5) & 1
    
    assert pins_uo_after["FLG_n"] == 1, "Error: FLG_n mutated during passthrough test!"
    assert trigger_out_after == 1, "DFT Timing Failure: TRIGGER_OUT failed to pass through instantly!"
    dut._log.info("Success: TRIGGER_OUT bypassed all filters and registers flawlessly.")

@cocotb.test()
async def test_trigger_out_passthrough_fixed(dut):
    dut._log.info("--- Running Fixed Test Case 9: TRIGGER_OUT A11 Passthrough ---")
    await initialize_dut(dut)
    dut.rst_n.value = 1
    
    # 1. Drive initial address tracking bit A11 (addr) to 0
    dut.ui_in.value = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    
    # Settle the anti-glitch filter blocks for 5 cycles first 
    # to guarantee FLG_n settles cleanly at 1 before running assertions
    dut._log.info("Settling the anti-glitch filter blocks post-initialization...")
    await ClockCycles(dut.clk, 5)
    await ReadOnly()
    
    pins_uo = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    # Cast explicitly to integer to extract Bit 5 of uio_out (TRIGGER_OUT)
    trigger_out = (dut.uio_out.value.integer >> 5) & 1
    
    # Verify clean initial starting states
    assert trigger_out == 0, f"Error: TRIGGER_OUT failed initial track. Expected 0, got {trigger_out}"
    assert pins_uo["FLG_n"] == 1, f"Error: Background status line FLG_n failed to settle at 1! Got: {pins_uo['FLG_n']}"
    
    # 2. Toggle the address bit to 1 (maps core_in.addr[0] / a11 to 1)
    await NextTimeStep()
    dut._log.info("Toggling address bit to 1 to verify INSTANT combinational passthrough...")
    dut.ui_in.value = pack_ui_in(addr=0x01, map_n=1, rd4=0, rd5=0)
    
    # 3. Check after exactly 1 clock cycle to prove it bypasses all 4-cycle loop delay logic paths
    await ClockCycles(dut.clk, 1)
    await ReadOnly() 
    
    pins_uo_after = unpack_uo_out(dut.uo_out.value.to_unsigned())
    trigger_out_after = (dut.uio_out.value.integer >> 5) & 1
    
    # CRITICAL EVENT VERIFICATION: Confirm TRIGGER_OUT responded instantly to the toggled address pin
    assert trigger_out_after == 1, f"DFT Timing Failure: TRIGGER_OUT failed to pass through instantly! Expected 1, got {trigger_out_after}"
    
    # Background Check: Ensure the filtered status lane didn't randomly change
    assert pins_uo_after["FLG_n"] == 1, "Error: Background indicator FLG_n shifted during passthrough test!"
    dut._log.info("Success: TRIGGER_OUT verified independently as an immediate combinational path.")

@cocotb.test()
async def test_flg_n_input_handling(dut):
    dut._log.info("--- Running Test Case 10: Flag Input Line System Disabling ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=0)
    # Wait 4 cycles to allow the master system anti-glitch filter to propagate the drop
    await ClockCycles(dut.clk, 4)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 1, "Error: /OS not disabled when FLG_IN_n is low"
    assert pins["FLG_n"] == 0, f"Error: FLG_n failed to filter-propagate low! Got: {pins['FLG_n']}"

# ==============================================================================
# CATEGORY E: PRIORITY INTERLOCKS & ARCHITECTURAL EDGE-CASES
# ==============================================================================

@cocotb.test()
async def test_global_enable_behavior(dut):
    dut._log.info("--- Running Test Case 11: Global Enable Pin Gating ---")
    mystic_clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(mystic_clock.start())
    
    dut.ui_in.value = 0x00
    dut.uio_in.value = 0x00
    dut.ena.value = 0
    dut.rst_n.value = 1
    
    await ClockCycles(dut.clk, 4)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 1, "Error: Outputs not disabled when ena is low"
    assert pins["FLG_n"] == 0, f"Error: FLG_n failed to filter-propagate low under zero enable! Got: {pins['FLG_n']}"

@cocotb.test()
async def test_basic_disable_by_cartridge(dut):
    dut._log.info("--- Running Test Case 12: Left Cartridge Priority Dominance Over BASIC ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=0, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["basic_n"] == 1, "Priority Interlocking Failure: Internal BASIC active alongside Left Cartridge!"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"

@cocotb.test()
async def test_os_hole_d000_bypass(dut):
    dut._log.info("--- Running Test Case 13: OS Hardware Hole Exception Separation ($D400) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["io_n"] == 0 and pins["os_n"] == 1, "Error: Overlap detected inside the $D000-$D7FF hardware block hole!"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"

@cocotb.test()
async def test_os_disable_by_ren(dut):
    dut._log.info("--- Running Test Case 14: Software OS Disabling for Extended RAM Window ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["os_n"] == 1, f"Error: /OS pulled low when explicitly disabled via software REN control loop! Got: {pins['os_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"

# ==============================================================================
# CATEGORY F: DIVIDER TESTS
# ==============================================================================

@cocotb.test()
async def test_all_divided_memory_decoders(dut):
    dut._log.info("--- Running Test Case 15: Multi-Signal Memory Decoder Verification ---")
    await initialize_dut(dut)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # --- TEST A: OS KERNEL ROM SELECT ($C000 maps to upper address blocks) ---
    # Force address bit fields to match LOWER_OS_ROM_START [15:11]
    dut.ui_in.value = pack_ui_in(addr=0x18, map_n=1, rd4=0, rd5=0) 
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    
    # Pulse 5 cycles to guarantee the divider hits sample_cnt==3 and steps to 0
    await ClockCycles(dut.clk, 5)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["os_n"] == 0, f"Error: os_n failed to activate. Got pins: {pins}"
    assert pins["basic_n"] == 1, "Error: basic_n misfired!"

    # --- TEST B: EXPANSION SLOT S4 SELECT ($8000) ---
    await NextTimeStep()
    dut.ui_in.value = pack_ui_in(addr=0x10, map_n=1, rd4=1, rd5=0)
    
    await ClockCycles(dut.clk, 5)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["s4_n"] == 0, f"Error: s4_n failed to activate. Got pins: {pins}"
    assert pins["os_n"] == 1, "Error: os_n failed to deactivate!"


@cocotb.test()
async def test_immediate_all_signals_masking(dut):
    dut._log.info("--- Running Fixed Immediate Multi-Signal Masking Verification ---")
    await initialize_dut(dut)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # 1. Establish an active memory access state matching your S5 decode equation ($A000 Area)
    # addr=0x14 drives a15=1, a14=0, a13=1. rd5=1 satisfies the S5 select gate conditions.
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    
    # 2. Settle the parallel divider registers past the 4-cycle window
    await ClockCycles(dut.clk, 5)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    # Validates your active-low cartridge lane to successfully bypass the setup phase
    assert pins["s5_n"] == 0, f"Setup Error: s5_n failed to activate before mask test. Got pins: {pins}"
    
    # 3. Trip the safety flag (FLG_IN_n = 0 forces system_disabled = 1)
    await NextTimeStep()
    dut._log.info("Tripping system safety block via FLG_IN_n...")
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=0)
    
    # 4. STEP A: Check IMMEDIATELY on the same delta cycle step (No clock pulse!)
    # The combinational bypass must force ALL 5 selectors and ci_n high instantly.
    await NextTimeStep()
    await ReadOnly()
    pins_instant = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins_instant["os_n"] == 1, "Asynchronous Masking Failure on os_n!"
    assert pins_instant["basic_n"] == 1, "Asynchronous Masking Failure on basic_n!"
    assert pins_instant["io_n"] == 1, "Asynchronous Masking Failure on io_n!"
    assert pins_instant["s4_n"] == 1, "Asynchronous Masking Failure on s4_n!"
    assert pins_instant["s5_n"] == 1, "Asynchronous Masking Failure on s5_n!"
    assert pins_instant["ci_n"] == 1, "Asynchronous Masking Failure on ci_n!"
    
    # FLG_n stays at 1 here because rst_n is high (1) and the clock hasn't pulsed
    assert pins_instant["FLG_n"] == 1, "Error: FLG_n changed without a clock edge or an active rst_n!"
    
    # 5. STEP B: Pulse the clock to let the anti-glitch filter shift its internal state
    await NextTimeStep()
    dut._log.info("Pulsing clock to allow the anti-glitch filter to propagate the safety fault...")
    await ClockCycles(dut.clk, 4)
    await ReadOnly()
    pins_filtered = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    # Now that the filter has been clocked 4 times, FLG_n clears to 0 safely
    assert pins_filtered["FLG_n"] == 0, "Safety Failure: FLG_n status line failed to drop to 0 after filter cycles!"
    dut._log.info("Success: All multi-lane outputs verified successfully across filter windows.")

# ==============================================================================
# CATEGORY 8: MANUFACTURING DFT PRODUCTION TEST MODE OPERATIONS
# ==============================================================================

@cocotb.test()
async def test_production_bypass_active(dut):
    dut._log.info("--- Running Test Case 17: Active-Low Production TESTMODE_n Active Bypass (0) ---")
    await initialize_dut(dut)
    
    # Assert active-low TESTMODE_n to 0 
    dut.ui_in.value = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, TESTMODE_n=0, FLG_IN_n=1)
    
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    # This will now PASS beautifully because testmode doesn't freeze the outputs anymore!
    assert pins["ci_n"] == 0, f"DFT Failure: Anti-glitch filter did not bypass combinationally! Got: {pins['ci_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"

@cocotb.test()
async def test_production_bypass_reset_interlock(dut):
    dut._log.info("--- Running Test Case 18: DFT Reset Priority and Interlock Masking ---")
    
    # 1. Initialize and settle the 2-stage clock synchronizer
    await initialize_dut(dut)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2) 
    
    # 2. Engage active-low TESTMODE_n (0) and configure memory inputs
    dut.ui_in.value = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, TESTMODE_n=0, FLG_IN_n=1)
    
    # Cycle 5 times to completely cross the divider registration boundary
    dut._log.info("Cycling 5 times to let the divider latch the input...")
    await ClockCycles(dut.clk, 5)
    
    # 3. VERIFY FUNCTIONAL DELAY OUTPUT BEFORE RESET (Must not be cleared yet)
    await ReadOnly()
    pins_before = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins_before["ci_n"] == 0, "Error: System should be passing data, not masked!"

    # 4. Step out of ReadOnly to perform the reset strike write
    await NextTimeStep() 
    
    # 5. Strike the active-low reset line to test the override
    dut._log.info("Applying rst_n to verify immediate override...")
    dut.rst_n.value = 0
    
    # Let the simulator process the reset assignment 
    await NextTimeStep()
    await ReadOnly()
    
    # 6. Verify absolute masking priority post-reset 
    current_uo = int(dut.uo_out.value)
    dut._log.info(f"Current uo_out register value reads: {current_uo}")
    
    # Expected value is exactly 63 because system_disabled goes true on rst_n=0,
    # immediately forcing all 6 memory selections high (1) combinationally,
    # while FLG_n drops to 0 asynchronously.
    assert current_uo == 63, f"DFT Security Breach: Expected 63 under reset clear, got {current_uo}"
    
    # Clean up and exit
    await NextTimeStep()
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
