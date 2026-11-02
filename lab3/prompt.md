### 7.4.1 实践任务一：添加 syscall 例外支持
本实践任务要求在 lab7 完成的 CPU 基础上，继续完成以下工作：
1）为 CPU 增加 MTC0、MFC0、ERET 指令。
2）为 CPU 增加 CP0 寄存器 Status、Cause、EPC。
3）为 CPU 增加 SYSCALL 指令，也就是增加 syscall 例外支持。
4）运行 lab8.zip 里的 func_lab8，要求成功通过仿真和上板验证。

本实践任务的硬件环境沿用 CPU_CDE，软件环境使用 lab8.zip。lab8.zip 只包含软件编译环境（func_lab8）。fun_lab8 和 func_lab7 相比，加入了 syscall 例外的测试内容。

请参考下列步骤完成本实践任务：
1）请先完成第 6 章的学习。
2）学习本章内容。
3）准备好 lab7 的实验环境和 CPU_CDE，该环境也会作为 lab8 的实验环境。
4）解压 lab8.zip，将 func_lab8/ 拷贝到 CPU_CDE/soft/ 目录里，与 func_lab7 同层次。
5）打开 cpu132_gettrace 工程（CPU_CDE/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr）。
6）对 cpu132_gettrace 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab8 的 coe（CPU_CDE/soft/func_lab8/obj/inst_ram.coe）。
7）运行 cpu132_gettrace 工程的仿真（进入仿真界面后，直接点击 run all 等待仿真运行完成），生成新的参考 Trace 文件 golden_trace.txt（CPU_CDE/cpu132_gettrace/golden_trace.txt）。注意，要等仿真运行完成，golden_trace.txt 才有完整的内容。
8）打开 myCPU 工程（CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr）。
9）对 myCPU 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab8 的 coe（CPU_CDE/soft/func_lab8/obj/inst_ram.coe）。
10）运行 myCPU 工程的仿真（进入仿真界面后，直接点击 run all），开始调试。
11）myCPU 仿真通过后，综合实现后生成比特流文件，进行上板验证（如果没有实验箱，请跳过这一步）。

---

### 7.4.2 实践任务二：添加其他例外支持
本实践任务要求在 lab8 完成的 CPU 基础上，继续完成以下工作：
1）为 CPU 增加 Break、地址错、整数溢出、保留指令例外支持。
2）为 CPU 增加 CP0 寄存器 Count、Compare、BadVAddr。
3）为 CPU 增加时钟中断支持，时钟中断要求固定绑定在硬件中断 5 号上，也就是 CP0 寄存器 Cause 的 IP7 上。
4）为 CPU 增加 6 个硬件中断支持，编号为 0～5，对应 CP0 寄存器 Cause 的 IP7～IP2。
5）为 CPU 增加 2 个软件中断支持，对应 CP0 寄存器 Cause 的 IP1～IP0。
6）运行 lab9.zip 里的 func_lab9，要求成功通过仿真和上板验证。
7）推荐上板运行 lab9 的记忆游戏程序（memory_game）。

本实践任务的硬件环境沿用 CPU_CDE，软件环境使用 lab9.zip。lab9.zip 只有两个软件编译环境：func_lab9 和 memory_game。func_lab9 和 func_lab8 相比，加入了前述的新增例外与中断的测试内容。

请参考下列步骤完成本实践任务：
1）学习本章内容。
2）准备好 lab8 的实验环境和 CPU_CDE，该环境也会作为 lab9 的实验环境。
3）解压 lab9.zip，将 func_lab9/ 拷贝到 CPU_CDE/soft/ 目录里，与 func_lab8 同层次。
4）打开 cpu132_gettrace 工程（CPU_CDE/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr）。
5）对 cpu132_gettrace 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab9 的 coe（CPU_CDE/soft/func_lab9/obj/inst_ram.coe）。
6）运行 cpu132_gettrace 工程的仿真（进入仿真界面后，直接点击 run all 等待仿真运行完成），生成新的参考 trace 文件 golden_trace.txt（CPU_CDE/cpu132_gettrace/golden_trace.txt）。注意，要等仿真运行完成，golden_trace.txt 才有完整的内容。
7）打开 myCPU 工程（CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr）。
8）对 myCPU 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab9 的 coe（CPU_CDE/soft/func_lab9/obj/inst_ram.coe）。
9）运行 myCPU 工程的仿真（进入仿真界面后，直接点击 run all），开始调试。
10）myCPU 仿真通过后，综合实现后生成 bit 流文件，进行上板验证（如果没有实验箱，请跳过这一步）。