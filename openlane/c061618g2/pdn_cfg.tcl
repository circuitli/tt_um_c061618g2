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

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET) -secondary_power $secondary

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

# 2. PURE NATIVE API BOUNDARY READING (Bypasses all JSON environment lookups)
set core_bbox [[ord::get_db_block] getCoreBBox]
set actual_core_left [expr {double([$core_bbox xMin]) / $db_units}]
set half_pitch_shift [expr {double($::env(PDN_VPITCH)) / 2.0}]

# Centers the first track perfectly inside the snapped boundary
set centered_v_offset [expr {$actual_core_left + $half_pitch_shift}]

utl::report "DYNAMIC PDN CONFIG CHECK: Extracted site width is ${site_width} um"
utl::report "DYNAMIC PDN CONFIG CHECK: Detected actual core left boundary at ${actual_core_left} um"
utl::report "DYNAMIC PDN CONFIG CHECK: Setting vertical stripe offset -> ${centered_v_offset} um"
# =============================================================================

define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# 1. Vertical Metal3 power stripes using the mathematically calculated core-relative offset
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) -offset $centered_v_offset -spacing $::env(PDN_VSPACING) -starts_with GROUND -extend_to_boundary

# 2. Interleaved Horizontal Power Rails (Row 0 = VSS, Row 1 = VDD) Clamped to Core
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset $interleaved_offset -starts_with GROUND -extend_to_core_ring
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -pitch $interleaved_pitch -offset 0.0 -starts_with POWER -extend_to_core_ring

# 3. Connect the rails directly to the vertical mesh stripes
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"

define_pdn_grid -macro -default -name macro_grid -starts_with GROUND

# 4. Bridge the vertical stripes up to the horizontal macro power trunks
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"