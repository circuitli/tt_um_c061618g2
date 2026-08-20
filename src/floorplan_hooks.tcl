# Force an intentional crash to test loading
THIS_IS_A_FAKE_COMMAND_TO_CRASH_THE_FLOW

# ========================================================
# LAYOUT REGIONS ---
# ========================================================
# 1. Create the region and define its bounding box coordinates (X1 Y1 X2 Y2)
create_region u_c061618g2_region 10.0 10.0 55.36 25.12

# 2. Bind the hierarchical instance to the region
assign_region u_c061618g2_region [get_cells -hierarchical *u_c061618g2]

#add_to_specification_region -name u_c061618g2_region -box {10.0 10.0 55.36 25.12} -instances [get_cells -hierarchical *u_c061618g2]
