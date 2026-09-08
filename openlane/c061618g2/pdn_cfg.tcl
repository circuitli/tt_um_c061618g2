# Target the native sub-macro grid object initialized by the LibreLane framework
# This avoids environment variable lookup conflicts entirely

add_pdn_stripe -grid macro_grid -layer Metal1 -width 0.44 -pitch 3.78 -offset 0
add_pdn_stripe -grid macro_grid -layer Metal3 -width 0.46 -pitch 5.52 -offset 11.04
add_pdn_stripe -grid macro_grid -layer Metal4 -width 1.80 -pitch 15.12 -offset 7.56

add_pdn_connect -grid macro_grid -layers "Metal1 Metal3"
add_pdn_connect -grid macro_grid -layers "Metal3 Metal4"
