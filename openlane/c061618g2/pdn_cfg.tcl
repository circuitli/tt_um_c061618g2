# Connect OpenLane's global standard nets directly to the primary domain
set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET)

# =============================================================================
# DYNAMIC GEOMETRY MATRIX CALCULATION (100% TECHNOLOGY INDEPENDENT)
# =============================================================================
set first_layout_row [lindex [[ord::get_db_block] getRows] 0]
set row_site_object  [$first_layout_row getSite]
set db_units         [[ord::get_db_tech] getDbUnitsPerMicron]

set calculated_rail_pitch [expr {double([$row_site_object getHeight]) / $db_units}]
set site_width            [expr {double([$row_site_object getWidth]) / $db_units}]

set interleaved_pitch  [expr {$calculated_rail_pitch * 2.0}]

# Fixes the Y-axis inversion by shifting off the 0.0 margin zone
set interleaved_offset_gnd [expr {$calculated_rail_pitch * 1.0}]
set interleaved_offset_vdd [expr {$calculated_rail_pitch * 2.0}]

set row_origin [$first_layout_row getOrigin]
set actual_core_left [expr {double([lindex $row_origin 0]) / $db_units}]

# Removes the cell_grid_center_shift to align center-lines to the layout window
set true_on_grid_offset $actual_core_left

utl::report "DYNAMIC PDN CONFIG CHECK: Core left and stripe offset locked to -> ${true_on_grid_offset} um"
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# 1. Unified Vertical Stripes (Uses environment arguments for width, pitch, and spacing)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $true_on_grid_offset -spacing $::env(PDN_VSPACING) -nets "$::env(GND_NET) $::env(VDD_NET)" -extend_to boundary

# 2. Interleaved Horizontal Power Rails (Uses environment arguments for layer and width)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset_gnd -nets $::env(GND_NET) -extend_to core_ring

add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset_vdd -nets $::env(VDD_NET) -extend_to core_ring

# 3. Horizontal Mesh Power Landing Pads (Uses environment arguments for horizontal network sizing)
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_HORIZONTAL_LAYER) -width $::env(PDN_HWIDTH) -pitch $::env(PDN_HPITCH) -offset $::env(PDN_HOFFSET) -spacing $::env(PDN_HSPACING) -nets "$::env(GND_NET) $::env(VDD_NET)" -extend_to boundary

# 4. Connect the rails directly via native layer connectivity strings
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"

# Compliance macro integration grid
define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
