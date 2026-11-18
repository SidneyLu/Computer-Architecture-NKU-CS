# func_lab9 golden trace in the SRAM gettrace project.
set proj D:/Architecture/lab4/CPU_CDE_SRAM/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr
set coe  D:/Architecture/lab4/CPU_CDE_SRAM/soft/func_lab9/obj/inst_ram.coe

open_project $proj
upgrade_ip [get_ips]
set ip [get_ips inst_ram]
if {$ip eq ""} {
    puts "ERROR: inst_ram IP not found"
    exit 1
}
set_property CONFIG.Coe_File $coe $ip
generate_target {synthesis simulation} $ip
export_ip_user_files -of_objects $ip -no_script -sync -force -quiet

set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation -mode behavioral
run 20ms
close_sim
close_project
exit
