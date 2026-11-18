# AXI CPU, func_lab9. Delay mode is whatever RANDOM_SEED is in confreg.v.
set proj D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/run_vivado/mycpu_prj1/mycpu.xpr
set core D:/Architecture/lab4/CPU_CDE_SRAM/mycpu_sram_verify/rtl/myCPU
set axi  D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/rtl/myCPU
set coe  D:/Architecture/lab4/CPU_CDE_AXI/soft/func_lab9/obj/inst_ram.coe
set ipsrc D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.srcs/sources_1/ip

open_project $proj
if {[llength [get_files -quiet -filter {NAME =~ "*mycpu_core.v"}]] == 0} {
    foreach f [glob $core/*.v] {
        if {![string match *mycpu_top.v $f]} {
            add_files $f
        }
    }
    add_files $core/mycpu.h
    set_property file_type {Verilog Header} [get_files mycpu.h]
    add_files $axi/mycpu_top.v
    add_files $axi/sram_axi_bridge.v
}
foreach ip {mult_gen_signed_0 mult_gen_unsigned_0 div_gen_signed_0 div_gen_unsigned_0} {
    if {[llength [get_ips -quiet $ip]] == 0} {
        add_files $ipsrc/$ip/$ip.xci
    }
}
upgrade_ip [get_ips]
set ip [get_ips axi_ram]
if {$ip eq ""} {
    puts "ERROR: axi_ram IP not found"
    exit 1
}
set_property CONFIG.Coe_File $coe $ip
generate_target {synthesis simulation} [get_ips]
export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet

set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation -mode behavioral
run 200ms
close_sim
close_project
exit
