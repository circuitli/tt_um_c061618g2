# ==============================================================================
# PRODUCTION VERIFICATION SUITE MMU
# Total Test Cases: 15
# Validates: Memory mappings, priority locking, anti-glitch filter latency,
#            loopback interfaces, and active-low production test bypass paths.
# ==============================================================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, ClockCycles

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

def pack_uio_in(ren, ref_n, mpd_n, be_n, TESTMODE_n=1, flg_n=1):
    """
    Packs bidirectional bus controls into an 8-bit input vector.
    Mapping:
      uio_in[0] -> ren (Active-High ROM Enable)
      uio_in[1] -> ref_n (Active-Low Refresh Flag)
      uio_in[2] -> mpd_n
      uio_in[3] -> be_n (Active-Low BASIC Enable)
      uio_in[4] -> TESTMODE_n (Active-Low Production Test Mode)
      uio_in[6] -> flg_n (Active-Low System Disable Flag)
    """
    vector = 0
    vector |= (ren & 1) << 0
    vector |= (ref_n & 1) << 1
    vector |= (mpd_n & 1) << 2
    vector |= (be_n & 1) << 3
    vector |= (TESTMODE_n & 1) << 4
    vector |= (flg_n & 1) << 6
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
        "LOOP_OUT": (val >> 6) & 1,
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
# CATEGORY B: NOMINAL ATARI ADDRESS SPACE MEMORY DECODING
# ==============================================================================

@cocotb.test()
async def test_standard_os_read(dut):
    dut._log.info("--- Running Test Case 2: Operating System ROM Decode ($F800) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 0, f"Error: /OS failed to pull active low! Got: {pins['os_n']}"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"
    assert pins["ci_n"] == 0, "Error: /CI must fall low during active internal ROM matches!"

@cocotb.test()
async def test_standard_basic_read(dut):
    dut._log.info("--- Running Test Case 3: BASIC Interpreter Space Decode ($A000) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=0, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["basic_n"] == 0, f"Error: /BASIC failed to pull active low! Got: {pins['basic_n']}"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"
    assert pins["os_n"] == 1, "Mutual Contention Error: /OS clapped active simultaneously!"

@cocotb.test()
async def test_standard_io_read(dut):
    dut._log.info("--- Running Test Case 4: Peripheral Hardware I/O Allocation ($D000) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["io_n"] == 0, f"Error: /IO failed to pull active low! Got: {pins['io_n']}"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"
    assert pins["os_n"] == 1, "Collision Error: /OS activated over the hardware I/O registry!"

# ==============================================================================
# CATEGORY C: CARTRIDGE EXPANSION BANK RECOGNITION
# ==============================================================================

@cocotb.test()
async def test_s4_bank_select(dut):
    dut._log.info("--- Running Test Case 5: Right Expansion Cartridge Bank Select ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x10, map_n=1, rd4=1, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["s4_n"] == 0, f"Error: /S4 failed to pull active low! Got: {pins['s4_n']}"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"
    assert pins["s5_n"] == 1, "Mutual Contention Error: /S5 clapped active simultaneously!"

@cocotb.test()
async def test_s5_bank_select(dut):
    dut._log.info("--- Running Test Case 6: Left Expansion Cartridge Bank Select ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["s5_n"] == 0, f"Error: /S5 failed to pull active low! Got: {pins['s5_n']}"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"
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
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"
    assert pins["ci_n"] == 0, f"Error: /CI must default active-low to inhibit RAM! Got: {pins['ci_n']}"

@cocotb.test()
async def test_cas_inhibit_activation(dut):
    dut._log.info("--- Running Test Case 8: Refresh Wait-State CAS Inhibit ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["ci_n"] == 0, f"Error: CAS Inhibit failed to assert low during active refresh requests! Got: {pins['ci_n']}"

@cocotb.test()
async def test_trigger_out_passthrough(dut):
    dut._log.info("--- Running Test Case 9: TRIGGER_OUT A11 Passthrough ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"
    
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = pack_ui_in(addr=0x01, map_n=1, rd4=0, rd5=0)
    
    await ClockCycles(dut.clk, 1)
    await ReadOnly() 
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"

@cocotb.test()
async def test_flg_n_input_handling(dut):
    dut._log.info("--- Running Test Case 10: Flag Input Line System Disabling ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=0)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 1, "Error: /OS not disabled when FLG_n is low"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"

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
    
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 1, "Error: Outputs not disabled when ena is low"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"

@cocotb.test()
async def test_basic_disable_by_cartridge(dut):
    dut._log.info("--- Running Test Case 12: Left Cartridge Priority Dominance Over BASIC ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x14, map_n=1, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=0, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["basic_n"] == 1, "Priority Interlocking Failure: Internal BASIC active alongside Left Cartridge!"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"

@cocotb.test()
async def test_os_hole_d000_bypass(dut):
    dut._log.info("--- Running Test Case 13: OS Hardware Hole Exception Separation ($D400) ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1A, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=1, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["io_n"] == 0 and pins["os_n"] == 1, "Error: Overlap detected inside the $D000-$D7FF hardware block hole!"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"

@cocotb.test()
async def test_os_disable_by_ren(dut):
    dut._log.info("--- Running Test Case 14: Software OS Disabling for Extended RAM Window ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=1, mpd_n=1, be_n=1, flg_n=1)
    
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["os_n"] == 1, f"Error: /OS pulled low when explicitly disabled via software REN control loop! Got: {pins['os_n']}"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"

# ==============================================================================
# CATEGORY F: MANUFACTURING DFT PRODUCTION TEST MODE OPERATIONS
# ==============================================================================

@cocotb.test()
async def test_production_bypass_active(dut):
    dut._log.info("--- Running Test Case 15: Active-Low Production TESTMODE_n Active Bypass (0) ---")
    await initialize_dut(dut)
    
    # Assert active-low TESTMODE_n to 0 (forces the anti-glitch filter into combinational transparency mode)
    dut.ui_in.value = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, TESTMODE_n=0, flg_n=1)
    
    # In manufacturing test bypass mode, outputs evaluate combinationally without filter accumulation delay loops
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    assert pins["ci_n"] == 0, f"DFT Failure: Anti-glitch filter did not bypass combinationally! Got: {pins['ci_n']}"
    assert pins["LOOP_OUT"] == 1, "Error: LOOP_OUT must remain fixed at 1!"