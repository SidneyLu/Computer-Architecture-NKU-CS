# Behavioral sim of mycpu with short VCD windows. Coe is already func_lab7.
set proj D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr
open_project $proj
set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
set_property xsim.simulate.log_all_signals false [get_filesets sim_1]
launch_simulation -mode behavioral
run all
close_sim
close_project
exit
