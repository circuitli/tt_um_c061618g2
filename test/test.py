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
from cocotb.triggers import Timer, ReadOnly, NextTimeStep

# ==============================================================================
# REPAIRED VECTOR PACKING AND UNPACKING UTILITIES
# ==============================================================================

def pack_ui_in(addr, map_n, rd4, rd5):
    """
    Packs scalar control lines and address slices into an 8-bit vector.
    Mapping:
      ui_in[4:0] -> addr[4:0] (Address lines A15 down to A11)
      ui_in[5]   -> map_n
      ui_in[6]   -> rd4
      ui_in[7]   -> rd5
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
      uio_in[0] -> ren
      uio_in[1] -> ref_n
      uio_in[2] -> mpd_n
      uio_in[3] -> be_n
      uio_in[4] -> TESTMODE_n
      uio_in[6] -> FLG_IN_n
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
    Initializes a pure clockless environment.
    Applies clean, standard hardware defaults to the asynchronous pads 
    DURING reset to prevent the filters from latching boot-up noise.
    """
    # Force system baseline to run (System enabled, not resetting)
    dut.ena.value = 1
    
    # Drive all pins to safe, inactive default values (All active-low signals high)
    # This ensures FLG_IN_n = 1, ref_n = 1, be_n = 1, etc.
    dut.ui_in.value = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    
    # Assert active-low reset to flush the internal logic gates
    dut.rst_n.value = 0
    await Timer(20, unit="ns")
    
    # Release reset cleanly into our stable baseline environment
    dut.rst_n.value = 1
    await Timer(50, unit="ns") # Give the asynchronous delay chains time to stabilize

async def drive_and_settle(dut, ui_val, uio_val, ena_val=1, settle_ns=50):
    """
    Drives all input vectors and environment flags simultaneously to eliminate 
    address skew, then steps time to cleanly resolve asynchronous feedback loops.
    """
    # 1. Drive ALL input ports and environment pins in parallel at the EXACT same instant
    dut.ui_in.value = ui_val
    dut.uio_in.value = uio_val
    dut.ena.value = ena_val
    
    # 2. Advance time by 1ps to break the infinite delta loop trap
    await Timer(1, unit="ps")
    
    # 3. Wait out the remaining settlement window cleanly
    await Timer(settle_ns, unit="ns")

# ==============================================================================
# CATEGORY A: FOUNDATIONAL BOOT & INITIALIZATION TASKS
# ==============================================================================

@cocotb.test()
async def test_project_init(dut):
    dut._log.info("--- Running Test Case 1: Subsystem Cold Boot Sequence ---")
    await initialize_dut(dut)
    await ReadOnly()
    dut._log.info("[+] Core clockless pipeline initialized successfully.")

# ==============================================================================
# CATEGORY B: NOMINAL ADDRESS SPACE MEMORY DECODING
# ==============================================================================

@cocotb.test()
async def test_standard_os_read(dut):
    dut._log.info("--- Running Test Case 2: Operating System ROM Decode ($F800) ---")
    await initialize_dut(dut)
    
    ui = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 0, f"Error: /OS failed to pull active low! Got: {pins['os_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["ci_n"] == 0, "Error: /CI must fall low during active internal ROM matches!"

@cocotb.test()
async def test_standard_basic_read(dut):
    dut._log.info("--- Running Test Case 3: BASIC Interpreter Space Decode ($A000) ---")
    await initialize_dut(dut)
    
    ui = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=0, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["basic_n"] == 0, f"Error: /BASIC failed to pull active low! Got: {pins['basic_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["os_n"] == 1, "Mutual Contention Error: /OS clapped active simultaneously!"

@cocotb.test()
async def test_standard_io_read(dut):
    dut._log.info("--- Running Test Case 4: Peripheral Hardware I/O Allocation ($D000) ---")
    await initialize_dut(dut)
    
    ui = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
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
    
    ui = pack_ui_in(addr=0x10, map_n=1, rd4=1, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["s4_n"] == 0, f"Error: /S4 failed to pull active low! Got: {pins['s4_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"
    assert pins["s5_n"] == 1, "Mutual Contention Error: /S5 clapped active simultaneously!"

@cocotb.test()
async def test_s5_bank_select(dut):
    dut._log.info("--- Running Test Case 6: Left Expansion Cartridge Bank Select ---")
    await initialize_dut(dut)
    
    ui = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
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
    
    await drive_and_settle(dut, ui_val=0xFF, uio_val=0xFF)
    
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
    
    ui = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["ci_n"] == 0, f"Error: CAS Inhibit failed to assert low during active refresh requests! Got: {pins['ci_n']}"
    
@cocotb.test()
async def test_trigger_out_passthrough_vector(dut):
    dut._log.info("--- Running Test Case 9: TRIGGER_OUT A11 Passthrough (Vector Verification) ---")
    await initialize_dut(dut)
    
    ui_init = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    uio_init = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui_init, uio_init)
    
    # 1. READ RAW BINARY STRING TO PREVENT CONVERSION CRASHES
    raw_str = str(dut.uio_out.value)
    dut._log.info(f"Raw binary state of uio_out: {raw_str}")
    
    if 'x' in raw_str.lower() or 'z' in raw_str.lower():
        raise AssertionError(f"CRITICAL: uio_out contains uninitialized data! Got: {raw_str}")
        
    trigger_out_initial = (int(raw_str, 2) >> 5) & 1
    assert trigger_out_initial == 0, f"Error: TRIGGER_OUT should track initial addr 0! Got: {trigger_out_initial}"
    
    ui_next = pack_ui_in(addr=0x01, map_n=1, rd4=0, rd5=0)
    await drive_and_settle(dut, ui_next, uio_init)

    # 2. CHECK THE SECOND VECTOR SAFELY
    raw_str_after = str(dut.uio_out.value)
    dut._log.info(f"Raw binary state after next vector: {raw_str_after}")
    
    if 'x' in raw_str_after.lower() or 'z' in raw_str_after.lower():
        raise AssertionError(f"CRITICAL: uio_out became uninitialized after drive! Got: {raw_str_after}")

    trigger_out_after = (int(raw_str_after, 2) >> 5) & 1
    assert trigger_out_after == 1, f"DFT Timing Failure: TRIGGER_OUT failed to pass through instantly! Got {trigger_out_after}"

@cocotb.test()
async def test_10_trigger_out_passthrough_integer(dut):
    dut._log.info("--- Running Test Case 10: TRIGGER_OUT A11 Passthrough (Integer Casting Verification) ---")
    await initialize_dut(dut)
    ui_init = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    uio_init = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui_init, uio_init)
    
    # Safe sampling using modern string parsing
    raw_uo = str(dut.uo_out.value)
    pins_uo = unpack_uo_out(int(raw_uo, 2))
    
    raw_uio = str(dut.uio_out.value)
    trigger_out = (int(raw_uio, 2) >> 5) & 1
    
    assert trigger_out == 0, f"Error: TRIGGER_OUT failed initial track. Expected 0, got {trigger_out}"
    assert pins_uo["FLG_n"] == 1, f"Error: Background status line FLG_n failed to settle at 1! Got: {pins_uo['FLG_n']}"

    ui_next = pack_ui_in(addr=0x01, map_n=1, rd4=0, rd5=0)
    await drive_and_settle(dut, ui_next, uio_init)

    # Safe sampling for step 2
    raw_uo_after = str(dut.uo_out.value)
    pins_uo_after = unpack_uo_out(int(raw_uo_after, 2))
    
    raw_uio_after = str(dut.uio_out.value)
    trigger_out_after = (int(raw_uio_after, 2) >> 5) & 1
    
    assert trigger_out_after == 1, f"DFT Timing Failure: TRIGGER_OUT failed to pass through instantly! Expected 1, got {trigger_out_after}"
    assert pins_uo_after["FLG_n"] == 1, "Error: Background indicator FLG_n shifted during passthrough test!"

@cocotb.test()
async def test_11_flg_n_input_handling(dut):
    dut._log.info("--- Running Test Case 11: Flag Input Line System Disabling ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=0)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["os_n"] == 1, "Error: /OS not disabled when FLG_IN_n is low"
    assert pins["FLG_n"] == 0, f"Error: FLG_n failed to filter-propagate low! Got: {pins['FLG_n']}"

@cocotb.test()
async def test_12_global_enable_behavior(dut):
    dut._log.info("--- Running Test Case 12: Global Enable Pin Gating ---")
    await initialize_dut(dut)
    # Drive all pins—including the enable flag—in a single atomic simulation step
    await drive_and_settle(dut, ui_val=0x00, uio_val=0x00, ena_val=0)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["os_n"] == 1, "Error: Outputs not disabled when ena is low"
    assert pins["FLG_n"] == 0, f"Error: FLG_n failed to filter-propagate low under zero enable! Got: {pins['FLG_n']}"

@cocotb.test()
async def test_13_basic_disable_by_cartridge(dut):
    dut._log.info("--- Running Test Case 13: Left Cartridge Priority Dominance Over BASIC ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=0, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["basic_n"] == 1, "Priority Interlocking Failure: Internal BASIC active alongside Left Cartridge!"

@cocotb.test()
async def test_14_os_hole_d000_bypass(dut):
    dut._log.info("--- Running Test Case 14: OS Hardware Hole Exception Separation ($D400) ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["io_n"] == 0 and pins["os_n"] == 1, "Error: Overlap detected inside the hardware hole!"

@cocotb.test()
async def test_15_os_disable_by_ren(dut):
    dut._log.info("--- Running Test Case 15: Software OS Disabling for Extended RAM Window ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=0, ref_n=1, mpd_n=1, be_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["os_n"] == 1, f"Error: /OS pulled low when disabled via software REN! Got: {pins['os_n']}"

@cocotb.test()
async def test_16_all_divided_memory_decoders(dut):
    dut._log.info("--- Running Test Case 16: Multi-Signal Memory Decoder Verification ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x18, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["os_n"] == 0, f"Error: os_n failed to activate. Got pins: {pins}"
    assert pins["basic_n"] == 1, "Error: basic_n misfired!"
    
    ui_s4 = pack_ui_in(addr=0x10, map_n=1, rd4=1, rd5=0)
    await drive_and_settle(dut, ui_s4, uio)
    
    raw_uo_s4 = str(dut.uo_out.value)
    pins_s4 = unpack_uo_out(int(raw_uo_s4, 2))
    assert pins_s4["s4_n"] == 0, f"Error: s4_n failed to activate. Got pins: {pins_s4}"
    assert pins_s4["os_n"] == 1, "Error: os_n failed to deactivate!"

@cocotb.test()
async def test_17_immediate_all_signals_masking(dut):
    dut._log.info("--- Running Fixed Immediate Multi-Signal Masking Verification ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    uio = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["s5_n"] == 0, f"Setup Error: s5_n failed to activate. Got pins: {pins}"
    
    # Changing uio_in requires waiting out settlement time using the standard driver pattern
    uio_masked = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=0)
    await drive_and_settle(dut, ui, uio_masked)
    
    raw_uo_instant = str(dut.uo_out.value)
    pins_instant = unpack_uo_out(int(raw_uo_instant, 2))
    assert pins_instant["os_n"] == 1, "Asynchronous Masking Failure on os_n!"
    assert pins_instant["basic_n"] == 1, "Asynchronous Masking Failure on basic_n!"
    assert pins_instant["io_n"] == 1, "Asynchronous Masking Failure on io_n!"
    assert pins_instant["s4_n"] == 1, "Asynchronous Masking Failure on s4_n!"
    assert pins_instant["s5_n"] == 1, "Asynchronous Masking Failure on s5_n!"
    assert pins_instant["ci_n"] == 1, "Asynchronous Masking Failure on ci_n!"

@cocotb.test()
async def test_18_production_bypass_active(dut):
    dut._log.info("--- Running Test Case 17: Active-Low Production TESTMODE_n Active Bypass (0) ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, TESTMODE_n=0, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo = str(dut.uo_out.value)
    pins = unpack_uo_out(int(raw_uo, 2))
    assert pins["ci_n"] == 0, f"DFT Failure: Anti-glitch filter did not bypass! Got: {pins['ci_n']}"
    assert pins["FLG_n"] == 1, "Error: FLG_n must remain fixed at 1!"

@cocotb.test()
async def test_19_production_bypass_reset_interlock(dut):
    dut._log.info("--- Running Test Case 18: DFT Reset Priority and Interlock Masking ---")
    await initialize_dut(dut)
    ui = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    uio = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, TESTMODE_n=0, FLG_IN_n=1)
    await drive_and_settle(dut, ui, uio)
    
    raw_uo_before = str(dut.uo_out.value)
    pins_before = unpack_uo_out(int(raw_uo_before, 2))
    assert pins_before["ci_n"] == 0, "Error: System should be passing data, not masked!"
    
    # Asserting rst_n asynchronously needs a settled step to resolve combinational loops
    dut.rst_n.value = 0
    await cocotb.triggers.Timer(1, unit="ns")
    
    raw_uo_current = str(dut.uo_out.value)
    current_uo = int(raw_uo_current, 2)
    assert current_uo == 63, f"DFT Security Breach: Expected 63 under reset clear, got {current_uo}"

@cocotb.test()
async def test_diagnose_uio_out_pins(dut):
    dut._log.info("--- Running Diagnostic: Mapping uio_out Pin States ---")
    await initialize_dut(dut)
    
    ui_init = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    uio_init = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, TESTMODE_n=1, FLG_IN_n=1)
    await drive_and_settle(dut, ui_init, uio_init)
    
    # Corrected: Use str() on the LogicObject value to safely fetch the binary string
    raw_str = str(dut.uio_out.value)
    
    # Reverse the string so index 0 matches the rightmost bit (LSB)
    reversed_str = raw_str[::-1] 
    
    dut._log.info("==================================================")
    dut._log.info(f"Full uio_out raw binary string (MSB -> LSB): {raw_str}")
    dut._log.info("==================================================")
    
    has_faulty_pins = False
    for bit_index, bit_value in enumerate(reversed_str):
        if bit_value.lower() in ['x', 'z']:
            dut._log.error(f"  -> Pin uio_out[{bit_index}] is stuck at: {bit_value.upper()}")
            has_faulty_pins = True
        else:
            dut._log.info(f"  -> Pin uio_out[{bit_index}] is clean: {bit_value}")
            
    dut._log.info("==================================================")
    
    if not has_faulty_pins:
        dut._log.info("Diagnostic complete: All pins are perfectly clean 0s or 1s!")
    else:
        raise AssertionError("Diagnostic failed: Found uninitialized/floating pins on uio_out.")
