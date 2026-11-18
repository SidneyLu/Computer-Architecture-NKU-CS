# SRAM-like CPU, func_lab9, random delay from the default confreg seed.
set proj D:/Architecture/lab4/CPU_CDE_SRAM/mycpu_sram_verify/run_vivado/mycpu_prj1/mycpu.xpr
set cpu  D:/Architecture/lab4/CPU_CDE_SRAM/mycpu_sram_verify/rtl/myCPU
set coe  D:/Architecture/lab4/CPU_CDE_SRAM/soft/func_lab9/obj/inst_ram.coe
set ipsrc D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.srcs/sources_1/ip

open_project $proj
if {[llength [get_files -quiet -filter {NAME =~ "*mycpu_core.v"}]] == 0} {
    add_files [glob $cpu/*.v]
    add_files $cpu/mycpu.h
    set_property file_type {Verilog Header} [get_files mycpu.h]
}
foreach ip {mult_gen_signed_0 mult_gen_unsigned_0 div_gen_signed_0 div_gen_unsigned_0} {
    if {[llength [get_ips -quiet $ip]] == 0} {
        add_files $ipsrc/$ip/$ip.xci
    }
}
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
launch_simulation -mode behavioral
run 80ms
close_sim
close_project
exit
