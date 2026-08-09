![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# MMU - Tiny Tapeout Implementation

This project is a Memory Management Unit (MMU). It handles memory mapping, peripheral address decoding, and operating system banking across the computer's memory space.

Unlike sequential system designs, this chip is **purely combinatorial, unclocked, and stateless**. It operates asynchronously, ignoring the infrastructure clock (`clk`) and reset (`rst_n`) lines.

## How it Works

The circuit reads the high-order address bits from the CPU and system control signals to activate various subsystem chip select outputs. It handles dynamic banking for the OS ROM, the BASIC ROM, and the Self-Test ROM space, freeing or exposing underlying DRAM.
  
## How to Run Simulations

This design is validated using asynchronous software simulations via **Cocotb**. 

To run the local testing environment manually:
```bash
cd test
make clean
make
```
Ensure your simulation signals look for immediate output changes following input state jumps, completely bypassing clock-edge checks.
