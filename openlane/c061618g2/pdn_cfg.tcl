# 1. Initialize the horizontal Metal1 cell follow-rails safely mapped to your row sites
add_pdn_stripe -layer Metal1 -width 0.44 -followpins

# 2. Draw the vertical Metal3 power stripes track-aligned to the 0.46 µm grid
add_pdn_stripe -layer Metal3 -width 0.46 -pitch 5.52 -offset 11.04

# 3. Draw heavy horizontal Metal4 distribution trunks to anchor the TopMetal1 vias safely
add_pdn_stripe -layer Metal4 -width 1.80 -pitch 15.12 -offset 7.56

# 4. Mirror the JSON matrix to drop the required via stacks cleanly
add_pdn_connect -layers "Metal1 Metal3"
add_pdn_connect -layers "Metal3 Metal4"
