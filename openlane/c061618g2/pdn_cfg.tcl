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
# DYNAMIC GEOMETRY MATRIX CALCULATION (100% TECHNOLOGY INDEPENDENT)
# =============================================================================
set first_layout_row [lindex [[ord::get_db_block] getRows] 0]
set row_site_object  [$first_layout_row getSite]
set db_units         [[ord::get_db_tech] getDbUnitsPerMicron]

set calculated_rail_pitch [expr {double([$row_site_object getHeight]) / $db_units}]
set site_width            [expr {double([$row_site_object getWidth]) / $db_units}]

set interleaved_pitch  [expr {$calculated_rail_pitch * 2.0}]
set interleaved_offset [expr {$calculated_rail_pitch * 1.0}]

# Extract snapped core left boundary directly from row coordinates
set row_origin [$first_layout_row getOrigin]
set actual_core_left [expr {double([lindex $row_origin 0]) / $db_units}]

# Aligns the stripe centerline perfectly to the internal cell site grid track (6.00 um)
set cell_grid_center_shift [expr {$site_width / 2.0}]
set true_on_grid_offset    [expr {$actual_core_left + $cell_grid_center_shift}]

utl::report "DYNAMIC PDN CONFIG CHECK: Detected actual core left boundary at ${actual_core_left} um"
utl::report "DYNAMIC PDN CONFIG CHECK: Centering vertical tracks perfectly on -> ${true_on_grid_offset} um"
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# =============================================================================
# EXPANDED MANUAL GRID ELIMINATING CHANEL REPAIR FAILURES
# =============================================================================
# Ground (VSS) Vertical Mesh System (Lands exactly on the 6.00 um track center column)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $true_on_grid_offset -nets $::env(GND_NET) -extend_to_boundary

# Power (VDD) Vertical Mesh System (Shifted by exactly half a pitch interval step)
set vdd_stripe_offset [expr {$true_on_grid_offset + (double($::env(PDN_VPITCH)) / 2.0)}]
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $vdd_stripe_offset -nets $::env(VDD_NET) -extend_to_boundary

# Change from -extend_to_core_ring to -extend_to_boundary to avoid edge-trimming channel crashes
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset -nets $::env(GND_NET) -extend_to_boundary
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset 0.0 -nets $::env(VDD_NET) -extend_to_boundary
# =============================================================================

# Connect the horizontal rails directly to your vertical mesh stripes
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"

define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"