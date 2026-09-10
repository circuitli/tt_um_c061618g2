# Connect OpenLane's global standard nets directly to the primary domain
set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET)

# =============================================================================
# DYNAMIC GRID TRACK EXTRACTION (100% HARDCODE-FREE & PDK INDEPENDENT)
# =============================================================================
set db_block         [ord::get_db_block]
set db_tech          [ord::get_db_tech]
set db_units         [$db_tech getDbUnitsPerMicron]

# 1. Dynamically extract standard cell row dimensions directly from layout
set first_layout_row [lindex [$db_block getRows] 0]
set row_site_object  [$first_layout_row getSite]
set calculated_rail_pitch [expr {double([$row_site_object getHeight]) / $db_units}]

set interleaved_pitch  [expr {$calculated_rail_pitch * 2.0}]
set interleaved_offset_gnd [expr {$calculated_rail_pitch * 1.0}]
set interleaved_offset_vdd [expr {$calculated_rail_pitch * 2.0}]

# 2. Extract the track spacing pitch to dynamically snap the core boundary
set vertical_layer_obj [$db_tech findLayer $::env(PDN_VERTICAL_LAYER)]
set track_grid         [$db_block findTrackGrid $vertical_layer_obj]

set track_pitch        [expr {double([$track_grid getSpaceX]) / $db_units}]
set track_start        [expr {double([lindex [$track_grid getGridX] 0]) / $db_units}]

# 3. Dynamic Snap Math: Locates the exact first track crossing after core left
set row_origin [$first_layout_row getOrigin]
set actual_core_left   [expr {double([lindex $row_origin 0]) / $db_units}]

set track_count_floor  [expr {int(($actual_core_left - $track_start) / $track_pitch)}]
set true_on_grid_offset [expr {$track_start + ($track_count_floor * $track_pitch)}]

utl::report "DYNAMIC PDN CONFIG CHECK: Snapped core track edge locked to -> ${true_on_grid_offset} um"
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# 1. Unified Vertical Stripes (Metal3) -> EXTEND_TO_BOUNDARY
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(FP_PDN_VWIDTH) -pitch $::env(FP_PDN_VPITCH) -offset $true_on_grid_offset -spacing $::env(FP_PDN_VSPACING) -nets "$::env(GND_NET) $::env(VDD_NET)" -extend_to_boundary

# 2. Interleaved Horizontal Power Rails (Metal1) -> EXTEND_TO_BOUNDARY
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset_gnd -nets $::env(GND_NET) -extend_to_boundary

add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset_vdd -nets $::env(VDD_NET) -extend_to_boundary

# 3. Horizontal Mesh Power Landing Pads (Metal4) -> EXTEND_TO_BOUNDARY
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_HORIZONTAL_LAYER) -width $::env(FP_PDN_HWIDTH) -pitch $::env(FP_PDN_HPITCH) -offset $::env(PDN_HOFFSET) -spacing $::env(FP_PDN_HSPACING) -nets "$::env(GND_NET) $::env(VDD_NET)" -extend_to_boundary

# 4. Connect the layers cleanly together via native layer connectivity strings
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"

# Compliance macro integration grid
define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
