# Relaunch the AXI mycpu simulation. RANDOM_SEED is already set in confreg.v.
set proj D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/run_vivado/mycpu_prj1/mycpu.xpr
open_project $proj
set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation -mode behavioral
run 400ms
close_sim
close_project
exit
