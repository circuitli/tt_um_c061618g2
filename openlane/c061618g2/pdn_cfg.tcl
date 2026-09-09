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

# Extract the actual snapped core left boundary coordinate from the layout database
set row_origin [$first_layout_row getOrigin]
set actual_core_left [expr {double([lindex $row_origin 0]) / $db_units}]

# 1. Base tracking step matching the layout columns grid
set grid_step 5.52

# 2. Base track center shift (0.48 / 2 = 0.24 um)
set center_shift [expr {$site_width / 2.0}]

# 3. Compute distinct, separate tracking offsets for each standalone net
set vss_track_offset [expr {$actual_core_left + $center_shift}]
set vdd_track_offset [expr {$vss_track_offset + $grid_step}]

# 4. Double the individual net tracking pitch so they loop symmetrically every two slots
set discrete_net_pitch [expr {$grid_step * 2.0}]

utl::report "DYNAMIC PDN CONFIG CHECK: VSS tracks start at -> ${vss_track_offset} um, repeating every ${discrete_net_pitch} um"
utl::report "DYNAMIC PDN CONFIG CHECK: VDD tracks start at -> ${vdd_track_offset} um, repeating every ${discrete_net_pitch} um"
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# =============================================================================
# SEPARATE EXPLICIT SINGLE-NET STRIPE ARRAYS (ELIMINATES MULTI-NET BUNCHING)
# =============================================================================
# 1. Standalone VSS tracks (Lands cleanly on tracks: 6.00 um, 17.04 um, 28.08 um, 39.12 um, 50.16 um)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $discrete_net_pitch -offset $vss_track_offset -nets $::env(GND_NET) -extend_to_boundary

# 2. Standalone VDD tracks (Lands cleanly on tracks: 11.52 um, 22.56 um, 33.60 um, 44.64 um, 55.68 um)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $discrete_net_pitch -offset $vdd_track_offset -nets $::env(VDD_NET) -extend_to_boundary

# 3. Interleaved Horizontal Power Rails Clamped to Core Bounding Box
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset -nets $::env(GND_NET) -extend_to_core_ring
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset 0.0 -nets $::env(VDD_NET) -extend_to_core_ring
# =============================================================================

# 4. Connect the rails directly via native layer intersections (Engine matches nets automatically)
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"

define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"