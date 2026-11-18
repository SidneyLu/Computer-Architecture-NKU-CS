# 2 slave / 1 master AXI3 crossbar. SI0 is instruction, SI1 is data.
set proj D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/run_vivado/mycpu_prj1/mycpu.xpr
set ipdir D:/Architecture/lab4/CPU_CDE_AXI/mycpu_axi_verify/rtl/xilinx_ip

open_project $proj
if {[llength [get_ips -quiet axi_crossbar_2x1]] == 0} {
    create_ip -name axi_crossbar -vendor xilinx.com -library ip -module_name axi_crossbar_2x1 -dir $ipdir
}
set ip [get_ips axi_crossbar_2x1]
# ID_WIDTH is the master-port ID width. Two slaves need one extra index bit,
# so a 3-bit thread ID on each slave requires ID_WIDTH = 4.
set_property -dict [list \
    CONFIG.NUM_SI {2} \
    CONFIG.NUM_MI {1} \
    CONFIG.PROTOCOL {AXI3} \
    CONFIG.ADDR_WIDTH {32} \
    CONFIG.DATA_WIDTH {32} \
    CONFIG.ID_WIDTH {4} \
    CONFIG.CONNECTIVITY_MODE {SAMD} \
    CONFIG.STRATEGY {0} \
    CONFIG.S00_THREAD_ID_WIDTH {3} \
    CONFIG.S01_THREAD_ID_WIDTH {3} \
    CONFIG.S00_ARB_PRIORITY {0} \
    CONFIG.S01_ARB_PRIORITY {15} \
    CONFIG.M00_A00_BASE_ADDR {0x0000000000000000} \
    CONFIG.M00_A00_ADDR_WIDTH {32} \
    CONFIG.M00_S00_READ_CONNECTIVITY {1} \
    CONFIG.M00_S01_READ_CONNECTIVITY {1} \
    CONFIG.M00_S00_WRITE_CONNECTIVITY {1} \
    CONFIG.M00_S01_WRITE_CONNECTIVITY {1} \
] $ip
generate_target {instantiation_template synthesis simulation} $ip
export_ip_user_files -of_objects $ip -no_script -sync -force -quiet
close_project
exit
