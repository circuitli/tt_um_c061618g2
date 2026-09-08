# Inject your absolute coordinates straight into the initialized toolchain workspace
# (This completely stops the redefinition memory panic)

add_pdn_stripe -grid $::env(PDN_CONN_GRID) -layer Metal1 -width 0.44 -pitch 3.78 -offset 0
add_pdn_stripe -grid $::env(PDN_CONN_GRID) -layer Metal3 -width 0.46 -pitch 5.52 -offset 11.04
add_pdn_stripe -grid $::env(PDN_CONN_GRID) -layer Metal4 -width 1.80 -pitch 15.12 -offset 7.56

add_pdn_connect -grid $::env(PDN_CONN_GRID) -layers "Metal1 Metal3"
add_pdn_connect -grid $::env(PDN_CONN_GRID) -layers "Metal3 Metal4"
