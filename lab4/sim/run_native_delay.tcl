# Native AXI func_lab9. Seed is whatever RANDOM_SEED is in the AXI confreg.
set proj D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/run_vivado/mycpu_prj1/mycpu.xpr
open_project $proj
set_property include_dirs {D:/Architecture/lab4/CPU_CDE_SRAM/mycpu_sram_verify/rtl/myCPU} [get_filesets sim_1]
set_property verilog_define {NATIVE_AXI} [get_filesets sim_1]
set_property xsim.elaborate.debug_level typical [get_filesets sim_1]
set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation -mode behavioral
run 50ms
close_sim
set_property verilog_define {} [get_filesets sim_1]
close_project
exit
