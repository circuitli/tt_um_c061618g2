# 1. Establish explicit net and voltage domain tracking targets
set_voltage_domain -name Core -power VDD -ground VSS

# 2. Initialize a standalone macro grid to completely kill the chip-level stdcell_grid loops
define_pdn_grid -name macro_grid -macro -voltage_domain Core

# 3. Draw horizontal Metal1 cell follow-rails cleanly across the logical rows
add_pdn_stripe -grid macro_grid -layer Metal1 -width 0.44 -pitch 3.78 -offset 0

# 4. Force vertical Metal3 stripes track-aligned strictly to the preferred vertical lanes
add_pdn_stripe -grid macro_grid -layer Metal3 -width 0.46 -pitch 5.52 -offset 11.04 -direction vertical

# 4. Draw the horizontal Metal4 power distribution trunks across the macro frame
add_pdn_stripe -grid macro_grid -layer Metal4 -width 0.44 -pitch 15.12 -offset 7.56 -direction horizontal

# 5. Connect the orthogonal layers together via standard macro via stacks
add_pdn_connect -grid macro_grid -layers "Metal1 Metal3"
add_pdn_connect -grid macro_grid -layers "Metal3 Metal4"