# Waveform program: syscall, other exceptions, soft/timer/hardware interrupts.
set proj D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr
set tb   D:/Architecture/lab3/sim/wave_tb.v

open_project $proj
if {[llength [get_files -quiet -all wave_tb.v]] == 0} {
    add_files -fileset sim_1 $tb
}
set_property include_dirs {D:/Architecture/lab3/sim} [get_filesets sim_1]
set_property top wave_tb [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
if {[catch {
    launch_simulation -mode behavioral
    run 2ms
    close_sim
} err]} {
    puts "WAVE_SIM_ERROR $err"
}
set_property top tb_top [get_filesets sim_1]
close_project
exit
