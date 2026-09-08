# Add the stripes completely clean—they will automatically target the current grid context
add_pdn_stripe -layer Metal1 -width 0.44 -pitch 3.78 -offset 0
add_pdn_stripe -layer Metal3 -width 0.46 -pitch 5.52 -offset 11.04
add_pdn_stripe -grid macro -layer Metal4 -width 1.80 -pitch 15.12 -offset 7.56

# Drop the vias onto the active grid context cleanly
add_pdn_connect -layers "Metal1 Metal3"
add_pdn_connect -layers "Metal3 Metal4"
