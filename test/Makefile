# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = tt_um_c061618g2.sv

# Fallback to your local formal project copy if PDK_ROOT isn't defined on Windows
PDK_ROOT ?= $(PWD)/formal
RAW_PDK_CELLS = $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

ifeq ($(SIM),verilator)
    VERILOG_SOURCES += $(PWD)/tb.v
    # 2. Feed the search search paths directly into Verilator's native -y system.
    # This instructs Verilator to look across the entire OpenLane PDK directory tree 
    # to automatically locate sg13g2.v and resolve the decoupling cells on its own.
    COMPILE_ARGS += -y $(PWD) -y $(PWD)/../src
    COMPILE_ARGS += -y /home/runner/.openlane/pdk/ihp-sg13g2/libs.ref/sg13g2/verilog
    COMPILE_ARGS += -y /home/runner/.openlane/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog
    COMPILE_ARGS += -y /opt/pdk/ihp-sg13g2/libs.ref/sg13g2/verilog
    COMPILE_ARGS += -v $(RAW_PDK_CELLS)

    # 3. CRITICAL FLAGS: Add -y to let Verilator discover your module dependencies,
    # and turn off MODDUP to ignore duplicate standard cell models if they overlap.
    COMPILE_ARGS += --timing -y $(PWD) -y $(PWD)/../src
    COMPILE_ARGS += -Wno-fatal -Wno-UNOPTFLAT -Wno-BLKANDNBLK -Wno-MODDUP
else ifeq ($(SIM),icarus)
    COMPILE_ARGS += -g2012
    COMPILE_ARGS += -DCOCOTB_SIM
ifneq ($(GATES),yes)

# RTL simulation:
    SIM_BUILD		= sim_build/rtl
    VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
    # 2. Instruct Icarus to append the .v suffix to search tokens 
    # when hunting down missing modules like sg13g2_decap_8.
    COMPILE_ARGS += -y $(PWD) -y $(PWD)/../src
    COMPILE_ARGS += -y /home/runner/.openlane/pdk/ihp-sg13g2/libs.ref/sg13g2/verilog
    COMPILE_ARGS += -y /home/runner/.openlane/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog
    COMPILE_ARGS += -y /opt/pdk/ihp-sg13g2/libs.ref/sg13g2/verilog
    COMPILE_ARGS += -v $(RAW_PDK_CELLS)

else

# Gate level simulation:
SIM_BUILD		= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
#COMPILE_ARGS    += -gno-specify
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DSIM

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

   # Define filenames
    CLEAN_LOCAL_CELLS = $(CURDIR)/sg13g2_stdcell_functional.v

    # 1. Create a local functional copy with the problematic lines deleted
    $(shell sed '/ifnone/d' $(RAW_PDK_CELLS) > $(CLEAN_LOCAL_CELLS))

    # 2. Append compilation macros
    COMPILE_ARGS += -DFUNCTIONAL -gno-specify

    # 3. Strip the raw PDK path from the sources and append our clean local version instead
    VERILOG_SOURCES := $(filter-out $(RAW_PDK_CELLS) %sg13g2_stdcell.v, $(VERILOG_SOURCES))
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
