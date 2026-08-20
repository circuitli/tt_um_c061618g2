# Force an intentional crash to test loading
THIS_IS_A_FAKE_COMMAND_TO_CRASH_THE_FLOW

# ========================================================
# LAYOUT REGIONS ---
# ========================================================
# 1. Clear any conflicting placement groups
catch { delete_region u_c061618g2_region }

# 2. Build the physical bounding constraint box (X1 Y1 X2 Y2 in microns)
create_region_fence u_c061618g2_region 10.0 10.0 55.36 25.12

# 3. Securely clamp your standard cells container instance inside the box
# The -hierarchical filter looks deep into the structural netlist logic trees
assign_region u_c061618g2_region [get_cells -hierarchical -filter "name =~ *u_c061618g2*"]

puts "=========================================================="
puts " SUCCESS: OPENROAD FORCED INSTANCE INTO THE BOX "
puts "=========================================================="
