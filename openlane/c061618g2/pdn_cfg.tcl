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
        if {$gnd == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET) -secondary_power $secondary

# =============================================================================
# DYNAMIC GEOMETRY MATRIX EXTRACTION
# =============================================================================
set first_layout_row [lindex [[ord::get_db_block] getRows] 0]
set row_site_object  [$first_layout_row getSite]
set db_units         [[ord::get_db_tech] getDbUnitsPerMicron]

set calculated_rail_pitch [expr {double([$row_site_object getHeight]) / $db_units}]
set site_width            [expr {double([$row_site_object getWidth]) / $db_units}]

set interleaved_pitch  [expr {$calculated_rail_pitch * 2.0}]
set interleaved_offset [expr {$calculated_rail_pitch * 1.0}]

set row_origin [$first_layout_row getOrigin]
set actual_core_left [expr {double([lindex $row_origin 0]) / $db_units}]

# Shift the vertical stripe by exactly 0.24 um to snap right onto the internal cell track grid column
set cell_grid_center_shift [expr {$site_width / 2.0}]
set true_on_grid_offset    [expr {$actual_core_left + $cell_grid_center_shift}]
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# 1. Vertical VSS (GROUND) stripes on Metal3
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $true_on_grid_offset -nets $::env(GND_NET) -extend_to_boundary

# 2. Vertical VDD (POWER) stripes on Metal3 (Shifted by exactly half a vertical pitch interval track)
set vdd_stripe_offset [expr {$true_on_grid_offset + (double($::env(PDN_VPITCH)) / 2.0)}]
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $vdd_stripe_offset -nets $::env(VDD_NET) -extend_to_boundary

# 3. Explicit Horizontal Core Rails - Extends cleanly to the core boundary to stop channel repair failures
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset -nets $::env(GND_NET) -extend_to_core_ring
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset 0.0 -nets $::env(VDD_NET) -extend_to_core_ring

# 4. Bind the horizontal rails and vertical stripes together via explicit crossover connections
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"

define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"