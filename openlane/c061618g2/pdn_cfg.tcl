# Connect OpenLane's global standard nets directly to the primary domain
set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET)

# =============================================================================
# DYNAMIC TECHNOLOGY GRID EXTRACTION
# =============================================================================
set db_block         [ord::get_db_block]
set db_tech          [ord::get_db_tech]
set db_units         [$db_tech getDbUnitsPerMicron]

# 1. Extract the physical hard boundaries of your macro canvas
set core_box  [$db_block getDieArea]
set core_left [expr {double([$core_box xMin]) / $db_units}]

# 2. DYNAMICALLY QUERY THE VERIFIED LAYOUT RAIL WIDTH FROM OPENLANE
set native_pdk_width $::env(PDN_RAIL_WIDTH)

# 3. Dynamically extract standard cell row spacing directly from the live layout
set first_layout_row [lindex [$db_block getRows] 0]
set row_site_object  [$first_layout_row getSite]
set calculated_rail_pitch [expr {double([$row_site_object getHeight]) / $db_units}]

# 4. TRACK ALIGNMENT MATH: Subtract the precise 0.08 um pin shift to stop via removals
set interleaved_pitch  [expr {$calculated_rail_pitch * 2.0}]
set interleaved_offset_vdd [expr {$calculated_rail_pitch - 0.08}]
set interleaved_offset_gnd [expr {($calculated_rail_pitch * 2.0) - 0.08}]
# =============================================================================

# Safely initialize your custom grid name to bypass the memory crash
define_pdn_grid -name stdcell_grid -starts_with GROUND -voltage_domains CORE

# =============================================================================
# DYNAMIC ALTERNATING RAILS (Perfectly centered on the -0.08 pin offset)
# =============================================================================
# =============================================================================
# REPAIRED: NATIVE FOLLOWPINS ENGINE (Automatically handles true pin fractions)
# =============================================================================
add_pdn_stripe -grid stdcell_grid \
               -layer $::env(PDN_RAIL_LAYER) \
               -width $::env(PDN_RAIL_WIDTH) \
               -followpins
# =============================================================================

# 1. Unified Vertical Stripes (Metal3) -> EXTEND_TO_BOUNDARY
add_pdn_stripe -grid stdcell_grid \
               -layer $::env(PDN_VERTICAL_LAYER) \
               -width $::env(FP_PDN_VWIDTH) \
               -pitch $::env(FP_PDN_VPITCH) \
               -offset $core_left \
               -spacing $::env(FP_PDN_VSPACING) \
               -nets "$::env(GND_NET) $::env(VDD_NET)" \
               -extend_to_boundary

# 3. Horizontal Mesh Power Landing Pads (Metal4) -> EXTEND_TO_BOUNDARY
add_pdn_stripe -grid stdcell_grid \
               -layer $::env(PDN_HORIZONTAL_LAYER) \
               -width $::env(FP_PDN_HWIDTH) \
               -pitch $::env(FP_PDN_HPITCH) \
               -offset $::env(FP_PDN_HOFFSET) \
               -spacing $::env(FP_PDN_HSPACING) \
               -nets "$::env(GND_NET) $::env(VDD_NET)" \
               -extend_to_boundary

# 4. Connect the layers cleanly together via native layer connectivity strings
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"

# Compliance macro integration grid
define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
