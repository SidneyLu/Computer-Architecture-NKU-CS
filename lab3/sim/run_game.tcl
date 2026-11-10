# One round of memory_game. Restores the func_lab9 instruction RAM afterwards.
set proj D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr
set tb   D:/Architecture/lab3/sim/game_tb.v
set inst_coe D:/Architecture/lab3/lab9/memory_game/obj/inst_ram.coe
set data_coe D:/Architecture/lab3/lab9/memory_game/obj/data_ram.coe
set inst_restore D:/Architecture/lab1/lab3/CPU_CDE/soft/func_lab9/obj/inst_ram.coe

open_project $proj
set old_def [get_property verilog_define [get_filesets sim_1]]

if {[llength [get_files -quiet -all game_tb.v]] == 0} {
    add_files -fileset sim_1 $tb
}
set_property verilog_define {SIM_FAST_IO} [get_filesets sim_1]
set_property top game_tb [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]

set inst_ip [get_ips inst_ram]
set data_ip [get_ips data_ram]
set_property CONFIG.Coe_File $inst_coe $inst_ip
set_property CONFIG.Coe_File $data_coe $data_ip
generate_target {simulation} [list $inst_ip $data_ip]

if {[catch {
    launch_simulation -mode behavioral
    run 40ms
    close_sim
} err]} {
    puts "GAME_SIM_ERROR $err"
}

set_property CONFIG.Coe_File $inst_restore $inst_ip
set_property CONFIG.Coe_File {no_coe_file_loaded} $data_ip
generate_target {simulation} [list $inst_ip $data_ip]
set_property verilog_define $old_def [get_filesets sim_1]
set_property top tb_top [get_filesets sim_1]
close_project
exit
