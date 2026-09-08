# -----------------------------------------------------------------------------
# 1. Initialize Global Core Power Infrastructure & Voltage Domains
# -----------------------------------------------------------------------------
source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set secondary []
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if { $vdd != $::env(VDD_NET)} {
        lappend secondary $vdd
        set db_net [[ord::get_db_block] findNet $vdd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }
    if { $gnd != $::env(GND_NET)} {
        lappend secondary $gnd
        set db_net [[ord::get_db_block] findNet $gnd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET) \
    -secondary_power $secondary

# -----------------------------------------------------------------------------
# 2. Define the Baseline Standard Cell Power Grid (Bypasses Channel Failures)
# -----------------------------------------------------------------------------
define_pdn_grid \
    -name stdcell_grid \
    -starts_with POWER \
    -voltage_domain CORE \
    -pins "Metal3"

# Draw the vertical Metal3 mesh stripes and extend them to prevent trimming loops
add_pdn_stripe \
    -grid stdcell_grid \
    -layer "Metal3" \
    -width $::env(PDN_VWIDTH) \
    -pitch $::env(PDN_VPITCH) \
    -offset $::env(PDN_VOFFSET) \
    -spacing $::env(PDN_VSPACING) \
    -starts_with POWER \
    -extend_to_boundary

# Core Standard Cell follow-rails on Metal1
if { $::env(PDN_ENABLE_RAILS) == 1 } {
    add_pdn_stripe \
        -grid stdcell_grid \
        -layer "Metal1" \
        -width 0.44 \
        -followpins

    add_pdn_connect \
        -grid stdcell_grid \
        -layers "Metal1 Metal3"
}

# -----------------------------------------------------------------------------
# 3. Define the Macro Grid Workspace with explicit halos to mirror the SRAM logic
# -----------------------------------------------------------------------------
define_pdn_grid \
    -macro \
    -default \
    -name macro \
    -starts_with POWER \
    -halo "0.0 0.0"

# Connect Metal4 down to your vertical Metal3 stripes natively
add_pdn_connect \
    -grid macro \
    -layers "Metal3 Metal4"
