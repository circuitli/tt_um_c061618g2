# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = tt_um_c061618g2.sv
RAW_PDK_CELLS = $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

ifeq ($(SIM),verilator)
    # --------------------------------------------------------------------------
    #  Verilator 5+ Path: High-Speed Timing GLS with UNTOUCHED PDK Libraries
    # --------------------------------------------------------------------------
    # Load the factory-original gate netlist from the build directory
    VERILOG_SOURCES += $(PWD)/../runs/wokwi/results/final/verilog/gl/tt_um_c061618g2.v
    VERILOG_SOURCES += $(RAW_LOCAL_CELLS)


    # Force the event engine and suppress unoptimized loop panics
    COMPILE_ARGS += --timing
    COMPILE_ARGS += -Wno-fatal -Wno-UNOPTFLAT -Wno-BLKANDNBLK

else ifeq ($(SIM),icarus)
ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
#COMPILE_ARGS    += -g2023

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
#COMPILE_ARGS    += -gno-specify
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DSIM
#COMPILE_ARGS    += -g2005
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_io/verilog/sg13g2_io.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

   # Define filenames
    CLEAN_LOCAL_CELLS = $(CURDIR)/sg13g2_stdcell_functional.v

    # 1. Create a local functional copy with the problematic lines deleted
    $(shell sed '/ifnone/d' $(RAW_PDK_CELLS) > $(CLEAN_LOCAL_CELLS))

    # 2. Append compilation macros
    COMPILE_ARGS += -DFUNCTIONAL -gno-specify

    # 3. Strip the raw PDK path from the sources and append our clean local version instead
    #VERILOG_SOURCES := $(filter-out $(RAW_PDK_CELLS) %sg13g2_stdcell.v, $(VERILOG_SOURCES))
    VERILOG_SOURCES += $(CLEAN_LOCAL_CELLS)
endif

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I..

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
