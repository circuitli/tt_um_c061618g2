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
# =============================================================================

# 1. Unified Vertical Stripes (Metal3) -> Appending directly to the default 'grid'
add_pdn_stripe -grid grid \
               -layer $::env(PDN_VERTICAL_LAYER) \
               -width $::env(FP_PDN_VWIDTH) \
               -pitch $::env(FP_PDN_VPITCH) \
               -offset $core_left \
               -spacing $::env(FP_PDN_VSPACING) \
               -nets "$::env(GND_NET) $::env(VDD_NET)" \
               -extend_to_boundary

# 3. Horizontal Mesh Power Landing Pads (Metal4) -> Appending directly to 'grid'
add_pdn_stripe -grid grid \
               -layer $::env(PDN_HORIZONTAL_LAYER) \
               -width $::env(FP_PDN_HWIDTH) \
               -pitch $::env(FP_PDN_HPITCH) \
               -offset $::env(FP_PDN_HOFFSET) \
               -spacing $::env(FP_PDN_HSPACING) \
               -nets "$::env(GND_NET) $::env(VDD_NET)" \
               -extend_to_boundary

# 4. Connect your custom upper layers down to the native, un-deleted PDK rails
add_pdn_connect -grid grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
add_pdn_connect -grid grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
add_pdn_connect -grid grid -layers "$::env(PDN_HORIZONTAL_LAYER) TopMetal1"

# Compliance macro integration grid
define_pdn_grid -macro -default -name macro_grid -starts_with GROUND
add_pdn_connect -grid macro_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
add_pdn_connect -grid macro_grid -layers "$::env(PDN_HORIZONTAL_LAYER) TopMetal1"
