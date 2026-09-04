![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

## 1. Overview
This project implements a Memory Management Unit (MMU) for traditional 8-bit computer architectures. Fabricated on the 130nm Silicon-Germanium (SiGe) BiCMOS process node (IHP SG13G2), this chip translates logical processor addresses into dynamic memory page-select signals.

## 2. How It Works
The hardware sits directly on the system's 16-bit address bus, intercepting the high-order address rows to decode sub-space windows. 

* **Address Transposition:** When an access cycle lands within a designated bank-switching window, the internal combinatorial matrix maps the current state of your system register configurations to translate the address space into physical memory array locations.
* **Synchronous Glitch Rejection:** To prevent transient signal hazards or routing path skew from corrupting downstream devices, the inputs and outputs are passed through multi-stage filters.These filters samples the internal state and use a voting network to dismiss moise spikes.

## 3. Hardware Framework Specification
The physical layout aligns with the Tiny Tapeout hardware tile format using the 130nm SiGe BiCMOS foundry platform (IHP SG13G2). The design is clockless.

## 4. Complete Pinout Mapping Matrix

### Primary Input Vector  (`ui_in`)
| Pin | Name | Type | Description |
|---|---|---|---|
| `ui_in[0]` | `a11` | Input | Address line 11 |
| `ui_in[1]` | `a12` | Input | Address line 12 |
| `ui_in[2]` | `a13` | Input | Address line 13 |
| `ui_in[3]` | `a14` | Input | Address line 14 |
| `ui_in[4]` | `a15` | Input | Address line 15 |
| `ui_in[5]` | `map_n` | Input | Active-low mapping control flag |
| `ui_in[6]` | `rd4` | Input | Cartridge expansion control line 4 |
| `ui_in[7]` | `rd5` | Input | Cartridge expansion control line 5 |

### Bidirectional Ports (`uio`)
| Pin | Name | Type | Description |
|---|---|---|---|
| `uio_in[0]` | `ren` | Input | Active-low ROM/RAM enable flag |
| `uio_in[1]` | `ref_n` | Input | Active-low dynamic refresh cycle signal |
| `uio_in[2]` | `mpd_n` | Input | Active-Low memory protect select flag |
| `uio_in[3]` | `be_n` | Input | Active-low interpreter memory space enable |
| `uio_in[4]` | `unused` | Reserved | Tied off internally |
| `uio_out[5]` | `TRIGGER_OUT` | Output | Dedicated Hardware Validation Output Trigger |
| `uio_in[6]` | `FLG_IN_n` | Input | Active-Low system error flag |
| `uio_in[7]` | `unused` | Reserved | Tied off internally |

### System Output Vector (`uo_out`)
| Pin | Name | Type | Description |
|---|---|---|---|
| `uo_out[0]` | `s5_n` | Output | Active-low expansion chip select 5 |
| `uo_out[1]` | `basic_n`| Output | Active-low internal interpreter chip select |
| `uo_out[2]` | `os_n` | Output | Active-low operating system ROM select |
| `uo_out[3]` | `ci_n` | Output | Filtered clock inhibit wait-state line |
| `uo_out[4]` | `io_n` | Output | Active-low peripheral I/O space select |
| `uo_out[5]` | `s4_n` | Output | Active-low expansion chip select 4 |
| `uo_out[6]` | `FLG_n`| Output | Active-Low error flag |
| `uo_out[7]` | `unnused` | Reserved | Static ground isolation line |

## 5. How to Run Simulation

### Software Pre-requisites
To execute the simulation matrix locally on your machine, the following environment dependencies must be satisfied:
* **Python 3.12+** is strictly required by the underlying cocotb test suite runners.
* **Icarus Verilog** (v12.0 or newer recommended for standard cell primitive parsing).
* **SymbiYosys** (required for compiling and evaluating formal bounded proofs).
* **Workcraft** (required for compiling and evaluating formal clockless proofs).


### Remote Execution
If local toolchains are unavailable, the entire verification infrastructure is fully compatible with cloud containers and can be simulated automatically within **GitHub Actions** continuous integration pipelines upon every remote branch push sequence.

## 5. Verification and Testing Modes
The architecture includes a comprehensive test framework divided into **three separate verification modes** to ensure absolute design stability across both ideal and post-synthesis environments.

### Mode 1: Event-Driven Behavioural Simulation
Validates the mathematical precision of the combinatorial address decoding matrix under ideal simulation conditions without cell propagation delays.
```bash
# Execute baseline RTL functional verification
make SIM=icarus
```

### Mode 2: Gate-Level Simulation (GLS)
Verifies the compiled structural netlist against real physical standard cell gate libraries, but removing some code problematic with SystemVerilog. Gate-level simulation requires an **additional parameter** (`GATES=yes`) passed to the compilation flag matrix. This tells the wrapper toolchain to bypass behavioral descriptions, pull in the synthesized gate netlist, and properly evaluate the synchronous initialization sequences required to prevent uninitialized `X`-propagation:
```bash
# Execute simplified gate-level simulation with the mandatory gates parameter
make SIM=icarus GATES=yes
```

### 𝐌𝐨𝐝𝐞 𝟑: Cycle-based Behavioural 𝐒𝐢𝐦𝐮𝐥𝐚𝐭𝐢𝐨𝐧
Verifies the compiled structural netlist against real physical standard cell gate primitives.
```bash
# Execute full gate-level simulation
make SIM=verilator
```

### Mode 4: Formal Verification
Mathematically proves all state-space properties, mutual exclusion bounds, and glitch-rejection characteristics of the filters across all possible input conditions. Formal routines bypass testbench stimulus scripts and are executed directly through SymbiYosys:
```bash
# Run formal bounded proofs using SymbiYosys
sby -f src/formal/mmu.sby
```

### Mode 5: Clockless Verification
Mathematically proves no dealocks or cycles exist through Workcraft:

