# Connect OpenLane's global standard nets directly to the primary domain
set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET)

# =============================================================================
# DYNAMIC GEOMETRY MATRIX CALCULATION (100% TECHNOLOGY INDEPENDENT)
# =============================================================================
# 1. Standard Cell Site Dimension Extraction (Safe database lookups)
set first_layout_row [lindex [[ord::get_db_block] getRows] 0]
set row_site_object  [$first_layout_row getSite]
set db_units         [[ord::get_db_tech] getDbUnitsPerMicron]

set calculated_rail_pitch [expr {double([$row_site_object getHeight]) / $db_units}]
set site_width            [expr {double([$row_site_object getWidth]) / $db_units}]

set interleaved_pitch  [expr {$calculated_rail_pitch * 2.0}]
set interleaved_offset [expr {$calculated_rail_pitch * 1.0}]

# 2. Extract snapped core left boundary directly from row coordinates
set row_origin [$first_layout_row getOrigin]
set actual_core_left [expr {double([lindex $row_origin 0]) / $db_units}]

# 3. Aligns the stripe centerline perfectly to the internal cell site grid track
set cell_grid_center_shift [expr {$site_width / 2.0}]
set true_on_grid_offset    [expr {$actual_core_left + $cell_grid_center_shift}]

utl::report "DYNAMIC PDN CONFIG CHECK: Core left is ${actual_core_left} um"
utl::report "DYNAMIC PDN CONFIG CHECK: Center slot locked to -> ${true_on_grid_offset} um using Pitch $::env(PDN_VPITCH) um"
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# =============================================================================
# POWER PAIR MESH ALLOCATION (NO VOLTAGE DOMAIN LOOP OVERHEADS)
# =============================================================================
# 1. Unified vertical command where VPITCH represents the full cycle of the pair
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $true_on_grid_offset -spacing $::env(PDN_VSPACING) -nets "$::env(GND_NET) $::env(VDD_NET)" -extend_to_boundary

# 2. Interleaved Horizontal Power Rails Clamped to Core Bounding Box
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset -nets $::env(GND_NET) -extend_to_core_ring
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset 0.0 -nets $::env(VDD_NET) -extend_to_core_ring

# 3. Connect the rails directly via native layer intersections
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
# =============================================================================

# =============================================================================
# TOP-LEVEL BLOCK TILING COMPLIANCE MESH
# =============================================================================
define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"