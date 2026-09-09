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

# Extract the actual snapped core left boundary coordinate
set row_origin [$first_layout_row getOrigin]
set actual_core_left [expr {double([lindex $row_origin 0]) / $db_units}]

# Snaps perfectly onto the internal cell site grid track column center (6.00 um)
set cell_grid_center_shift [expr {$site_width / 2.0}]
set vss_on_grid_offset     [expr {$actual_core_left + $cell_grid_center_shift}]

# Shift VDD by exactly ONE vertical cell track pitch to catch an odd VDD column (6.48 um)
set vdd_on_grid_offset     [expr {$vss_on_grid_offset + $site_width}]

utl::report "DYNAMIC PDN CONFIG CHECK: Detected actual core left boundary at ${actual_core_left} um"
utl::report "DYNAMIC PDN CONFIG CHECK: Locking VSS track to -> ${vss_on_grid_offset} um, VDD track to -> ${vdd_on_grid_offset} um"
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# =============================================================================
# STANDARD SEPARATED POWER NET STRIPE PAIRS
# =============================================================================
# Ground (VSS) Vertical Mesh System (Sits on even columns: 6.00 um, 17.04 um...)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $vss_on_grid_offset -nets $::env(GND_NET) -extend_to_boundary

# Power (VDD) Vertical Mesh System (Sits on odd columns: 6.48 um, 17.52 um...)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $vdd_on_grid_offset -nets $::env(VDD_NET) -extend_to_boundary

# Interleaved Horizontal Power Rails (Row 0 = VSS, Row 1 = VDD) Clamped to Core
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset -nets $::env(GND_NET) -extend_to_core_ring
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset 0.0 -nets $::env(VDD_NET) -extend_to_core_ring [1.2]
# =============================================================================

# 3. Clean native via connectivity layers calls (No illegal flags, no crashes)
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"

define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"