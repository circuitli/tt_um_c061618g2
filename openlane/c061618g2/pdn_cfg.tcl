# Target the framework's native grid template instance cleanly without variables

add_pdn_stripe -grid stdcell_grid -layer Metal1 -width 0.44 -pitch 3.78 -offset 0
add_pdn_stripe -grid stdcell_grid -layer Metal3 -width 0.46 -pitch 5.52 -offset 11.04
add_pdn_stripe -grid stdcell_grid -layer Metal4 -width 1.80 -pitch 15.12 -offset 7.56

add_pdn_connect -grid stdcell_grid -layers "Metal1 Metal3"
add_pdn_connect -grid stdcell_grid -layers "Metal3 Metal4"
