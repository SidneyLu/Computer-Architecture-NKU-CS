# Recreate the class-SRAM project after mycpu.xpr was truncated.
set proj_dir D:/Architecture/lab4/CPU_CDE_SRAM/mycpu_sram_verify/run_vivado/mycpu_prj1
set root     D:/Architecture/lab4/CPU_CDE_SRAM/mycpu_sram_verify
set ipsrc    D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.srcs/sources_1/ip

file delete -force $proj_dir/mycpu.xpr
create_project mycpu $proj_dir -part xc7a200tfbg676-2 -force

set cpu $root/rtl/myCPU
add_files [glob $cpu/*.v]
add_files $cpu/mycpu.h
set_property file_type {Verilog Header} [get_files mycpu.h]
add_files [list \
    $root/rtl/BRIDGE/bridge_1x2.v \
    $root/rtl/CONFREG/confreg.v \
    $root/rtl/soc_sram_lite_top.v \
    $root/rtl/ram_wrap/sram_wrap.v \
]
add_files [list \
    $ipsrc/mult_gen_signed_0/mult_gen_signed_0.xci \
    $ipsrc/mult_gen_unsigned_0/mult_gen_unsigned_0.xci \
    $ipsrc/div_gen_signed_0/div_gen_signed_0.xci \
    $ipsrc/div_gen_unsigned_0/div_gen_unsigned_0.xci \
    $root/rtl/xilinx_ip/clk_pll/clk_pll.xci \
    $root/rtl/xilinx_ip/data_ram/data_ram.xci \
    $root/rtl/xilinx_ip/inst_ram/inst_ram.xci \
]
add_files -fileset constrs_1 $root/run_vivado/soc_lite.xdc
add_files -fileset sim_1 $root/testbench/mycpu_tb.v

set_property top soc_sram_lite_top [current_fileset]
set_property top tb_top [get_filesets sim_1]
set_property include_dirs [list $cpu] [current_fileset]
set_property include_dirs [list $cpu] [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
set_property xsim.elaborate.debug_level typical [get_filesets sim_1]

close_project
exit
