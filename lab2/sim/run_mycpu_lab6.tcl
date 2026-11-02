# Simulate mycpu against func_lab6 golden_trace.
set proj D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr
set coe  D:/Architecture/lab1/lab3/CPU_CDE/soft/func_lab7/obj/inst_ram.coe

open_project $proj
upgrade_ip [get_ips]
set ip [get_ips inst_ram]
if {$ip eq ""} {
    puts "ERROR: inst_ram IP not found"
    exit 1
}
set_property CONFIG.Coe_File $coe $ip
generate_target {synthesis simulation} [get_ips]
export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet

set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
set_property xsim.simulate.log_all_signals false [get_filesets sim_1]
launch_simulation -mode behavioral
run all
close_sim
close_project
exit
