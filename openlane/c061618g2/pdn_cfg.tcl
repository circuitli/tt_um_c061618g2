# 1. Establish the domain and standalone macro grid framework with the mandatory type target
set_voltage_domain -name Core -power VDD -ground VSS
define_pdn_grid -name macro_grid -macro -default -voltage_domain Core

# 2. Draw the horizontal Metal1 standard cell rails cleanly across the logical rows
add_pdn_stripe -grid macro_grid -layer Metal1 -width 0.44 -pitch 3.78 -offset 0

# 3. Draw the vertical Metal3 power trunks track-aligned to the 0.46 µm grid
add_pdn_stripe -grid macro_grid -layer Metal3 -width 0.46 -pitch 5.52 -offset 11.04 -direction vertical

# 4. Draw heavy horizontal Metal4 distribution trunks to anchor the TopMetal1 vias safely
add_pdn_stripe -grid macro_grid -layer Metal4 -width 1.80 -pitch 15.12 -offset 7.56 -direction horizontal

# 5. Mirror the JSON matrix to drop the required via stacks
add_pdn_connect -grid macro_grid -layers "Metal1 Metal3"
add_pdn_connect -grid macro_grid -layers "Metal3 Metal4"
