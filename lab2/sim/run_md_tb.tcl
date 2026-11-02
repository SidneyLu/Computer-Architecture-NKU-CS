# Module-level random test. Uses the existing project so the four IP cores
# are already generated. Added files are removed before the project is closed.
set proj D:/Architecture/lab1/lab3/CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr
set tbdir {D:/Architecture/lab2/lab6/乘法器模块级验证顶层}
set added [list $tbdir/mul.v $tbdir/div.v $tbdir/mul_tb.v $tbdir/div_tb.v]

open_project $proj
set orig_top [get_property top [get_filesets sim_1]]
add_files -fileset sim_1 -norecurse $added

proc mdtb_cleanup {orig added} {
    catch {close_sim}
    catch {remove_files -fileset sim_1 $added}
    catch {set_property top $orig [get_filesets sim_1]}
    catch {update_compile_order -fileset sim_1}
}

if {[catch {
    set_property top mul_tb [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
    update_compile_order -fileset sim_1
    launch_simulation -mode behavioral
    puts "MDTB mul_tb start"
    run 10us
    puts "MDTB mul_tb done"
    close_sim

    set_property top div_tb [get_filesets sim_1]
    launch_simulation -mode behavioral
    puts "MDTB div_tb start"
    run 30us
    puts "MDTB div_tb done"
    close_sim
} msg]} {
    puts "MDTB FAIL: $msg"
}

mdtb_cleanup $orig_top $added
close_project
exit
