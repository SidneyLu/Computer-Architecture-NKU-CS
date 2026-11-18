# AXI CPU with the 2x1 crossbar. Fixed delay (RANDOM_SEED 16'h00FF).
set proj D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/run_vivado/mycpu_prj1/mycpu.xpr
open_project $proj
set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation -mode behavioral
run 40ms
close_sim
close_project
exit
