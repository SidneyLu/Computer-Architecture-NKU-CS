# Native AXI core: pipeline drives AXI, crossbar still merges the two ports.
set proj D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/run_vivado/mycpu_prj1/mycpu.xpr
set rtl  D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/rtl/myCPU
open_project $proj
foreach f {if_stage_axi.v exe_stage_axi.v mycpu_core_axi.v} {
    if {[llength [get_files -quiet $f]] == 0} {
        add_files -fileset sources_1 $rtl/$f
    }
}
set_property include_dirs {D:/Architecture/lab4/CPU_CDE_SRAM/mycpu_sram_verify/rtl/myCPU} [get_filesets sim_1]
set_property verilog_define {NATIVE_AXI WAVE_DUMP} [get_filesets sim_1]
set_property xsim.elaborate.debug_level all [get_filesets sim_1]
set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation -mode behavioral
run 80us
close_sim
set_property verilog_define {} [get_filesets sim_1]
set_property xsim.elaborate.debug_level typical [get_filesets sim_1]
close_project
exit
