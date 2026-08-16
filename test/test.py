# ==============================================================================
# PRODUCTION VERIFICATION SUITE FOR MMU
# ==============================================================================
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

def pack_ui_in(addr, map_n, rd4, rd5):
    """
    Packs scalar control lines and address slices into an 8-bit vector.
    Mapping:
      ui_in[4:0] -> addr[4:0] (Address lines a15 down to a11)
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

def pack_uio_in(ren, ref_n, mpd_n, be_n, flg_n, loop_in):
    """
    Packs bidirectional bus controls into an 8-bit input vector.
    Mapping:
      uio_in[0] -> ren
      uio_in[1] -> ref_n
      uio_in[2] -> mpd_n
      uio_in[3] -> be_n
      uio_in[4] -> flg_n
      uio_in[6] -> loop_in
    """
    vector = 0
    vector |= (ren & 1) << 0
    vector |= (ref_n & 1) << 1
    vector |= (mpd_n & 1) << 2
    vector |= (be_n & 1) << 3
    vector |= (flg_n & 1) << 4
    vector |= (loop_in & 1) << 6
    return vector

def unpack_uo_out(val):
    """
    Unpacks the 8-bit hardware output vector into readable key names.
    Mapping matches top-level pin continuous routing matrix assignments.
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
    """
    # Start a stable 50 MHz clock loop (20ns period) to clear IHP platform limits
    mystic_clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(mystic_clock.start())
    
    # Assert active-low master reset structure
    dut.ena.value = 1
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    # Release master reset synchronised to clock boundaries
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

# ==============================================================================
# SUB-SECTION: FUNCTIONAL HARDWARE TEST BENCH BENCHMARKS
# ==============================================================================

@cocotb.test()
async def test_project_init(dut):
    dut._log.info("--- Running Test Case 1: Subsystem Cold Boot Sequence ---")
    await initialize_dut(dut)
    await ReadOnly()
    dut._log.info("[+] Core clock tree and reset pipeline initialized successfully.")

@cocotb.test()
async def test_disconnected_pmod_behavior(dut):
    dut._log.info("--- Running Test Case 2: Disconnected Peripheral Float State ---")
    await initialize_dut(dut)
    
    # Unpopulated PMOD pins drift cleanly high to 1 via pull-up networks
    dut.ui_in.value = 0xFF
    dut.uio_in.value = 0xFF
    
    # Allow 3 complete edges for the sequential anti-glitch filter register to step
    for _ in range(3):
        await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    # Verify that floating high-impedance inputs keep selection structures idle
    assert pins["os_n"] == 1, "Error: /OS leaked low during disconnected state!"
    assert pins["basic_n"] == 1, "Error: /BASIC leaked low during disconnected state!"
    assert pins["io_n"] == 1, "Error: /IO leaked low during disconnected state!"
    assert pins["s4_n"] == 1, "Error: /S4 leaked low during disconnected state!"
    assert pins["s5_n"] == 1, "Error: /S5 leaked low during disconnected state!"
    # True Atari equation pulls /CI low if ref_n drifts high to 1
    assert pins["ci_n"] == 0, f"Error: /CI must default active-low! Got: {pins['ci_n']}"

@cocotb.test()
async def test_standard_os_read(dut):
    dut._log.info("--- Running Test Case 3: Operating System ROM Decode ($F800) ---")
    await initialize_dut(dut)
    
    # Target address 0x1F satisfying the complex nested Atari OS equations
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=0, mpd_n=1, be_n=1, flg_n=1, loop_in=1)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 0, f"Error: /OS failed to pull active low! Got: {pins['os_n']}"
    assert pins["basic_n"] == 1, "Mutual Contention Error: /BASIC clapped active simultaneously!"
    assert pins["io_n"] == 1, "Mutual Contention Error: /IO clapped active simultaneously!"
    assert pins["s4_n"] == 1, "Mutual Contention Error: /S4 clapped active simultaneously!"
    assert pins["s5_n"] == 1, "Mutual Contention Error: /S5 clapped active simultaneously!"

@cocotb.test()
async def test_standard_basic_read(dut):
    dut._log.info("--- Running Test Case 4: BASIC Interpreter Space Decode ($A000) ---")
    await initialize_dut(dut)
    
    # Target address 0x18 maps to active BASIC criteria bounds
    # Set ren=1 to uniquely isolate BASIC memory space without overlapping OS select terms
    dut.ui_in.value = pack_ui_in(addr=0x18, map_n=0, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=0, flg_n=1, loop_in=1)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["basic_n"] == 0, f"Error: /BASIC failed to pull active low! Got: {pins['basic_n']}"
    assert pins["os_n"] == 1, "Mutual Contention Error: /OS clapped active simultaneously!"
    assert pins["io_n"] == 1, "Mutual Contention Error: /IO clapped active simultaneously!"
    assert pins["s4_n"] == 1, "Mutual Contention Error: /S4 clapped active simultaneously!"
    assert pins["s5_n"] == 1, "Mutual Contention Error: /S5 clapped active simultaneously!"

@cocotb.test()
async def test_standard_io_read(dut):
    dut._log.info("--- Running Test Case 5: Peripheral Hardware I/O Allocation ($D000) ---")
    await initialize_dut(dut)
    
    # Target address 0x1B maps precisely to the IO decoding gate conditions
    # Set ren=1 to isolate Peripheral I/O space without triggering overlapping OS terms
    dut.ui_in.value = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, flg_n=1, loop_in=1)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["io_n"] == 0, f"Error: /IO failed to pull active low! Got: {pins['io_n']}"
    assert pins["os_n"] == 1, "Mutual Contention Error: /OS clapped active simultaneously!"
    assert pins["basic_n"] == 1, "Mutual Contention Error: /BASIC clapped active simultaneously!"
    assert pins["s4_n"] == 1, "Mutual Contention Error: /S4 clapped active simultaneously!"
    assert pins["s5_n"] == 1, "Mutual Contention Error: /S5 clapped active simultaneously!"

@cocotb.test()
async def test_s4_bank_select(dut):
    dut._log.info("--- Running Test Case 6: Right Expansion Cartridge Bank Select ---")
    await initialize_dut(dut)
    
    # Target address 0x10 activates the cartridge bank routing logic gates
    dut.ui_in.value = pack_ui_in(addr=0x10, map_n=1, rd4=1, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=0, mpd_n=1, be_n=1, flg_n=1, loop_in=1)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["s4_n"] == 0, f"Error: /S4 failed to pull active low! Got: {pins['s4_n']}"
    assert pins["s5_n"] == 1, "Mutual Contention Error: /S5 clapped active simultaneously!"

@cocotb.test()
async def test_s5_bank_select(dut):
    dut._log.info("--- Running Test Case 7: Left Expansion Cartridge Bank Select ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x10, map_n=1, rd4=0, rd5=1)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=0, mpd_n=1, be_n=1, flg_n=1, loop_in=1)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["s5_n"] == 0, f"Error: /S5 failed to pull active low! Got: {pins['s5_n']}"
    assert pins["s4_n"] == 1, "Mutual Contention Error: /S4 clapped active simultaneously!"

@cocotb.test()
async def test_cas_inhibit_activation(dut):
    dut._log.info("--- Running Test Case 8: Refresh Wait-State CAS Inhibit ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1B, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=1, mpd_n=1, be_n=1, flg_n=1, loop_in=1)
    
    for _ in range(3):
        await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["ci_n"] == 0, f"Error: /CI failed to transition low! Got: {pins['ci_n']}"

@cocotb.test()
async def test_trigger_out_passthrough(dut):
    dut._log.info("--- Running Test Case 9: TRIGGER_OUT A11 Passthrough ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x00, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, flg_n=1, loop_in=1)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    trigger_out = (dut.uio_out.value.to_unsigned() >> 5) & 1
    assert trigger_out == 0, f"Error: TRIGGER_OUT failed to track A11 low! Got: {trigger_out}"
    
    await RisingEdge(dut.clk)
    dut.ui_in.value = pack_ui_in(addr=0x01, map_n=1, rd4=0, rd5=0)
    
    await RisingEdge(dut.clk)
    await ReadOnly() 
    trigger_out = (dut.uio_out.value.to_unsigned() >> 5) & 1
    assert trigger_out == 1, f"Error: TRIGGER_OUT failed to track A11 high! Got: {trigger_out}"

@cocotb.test()
async def test_external_board_loopback(dut):
    dut._log.info("--- Running Test Case 10: PCB External Wire Loopback ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x10, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=1, ref_n=0, mpd_n=1, be_n=1, flg_n=1, loop_in=0)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["LOOP_OUT"] == 1, f"Error: LOOP_OUT failed under loopback override! Got: {pins['LOOP_OUT']}"

@cocotb.test()
async def test_flg_n_input_handling(dut):
    dut._log.info("--- Running Test Case 11: Flag Input Line System Disabling ---")
    await initialize_dut(dut)
    
    dut.ui_in.value = pack_ui_in(addr=0x1F, map_n=1, rd4=0, rd5=0)
    dut.uio_in.value = pack_uio_in(ren=0, ref_n=0, mpd_n=1, be_n=1, flg_n=0, loop_in=1)
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 1, "Error: /OS not disabled when FLG_n is low"

@cocotb.test()
async def test_global_enable_behavior(dut):
    dut._log.info("--- Running Test Case 12: Global Enable Pin Gating ---")
    mystic_clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(mystic_clock.start())
    
    dut.ui_in.value = 0x00
    dut.uio_in.value = 0x00
    dut.ena.value = 0
    dut.rst_n.value = 1
    
    await RisingEdge(dut.clk)
    await ReadOnly()
    pins = unpack_uo_out(dut.uo_out.value.to_unsigned())
    
    assert pins["os_n"] == 1, "Error: Outputs not disabled when ena is low"
