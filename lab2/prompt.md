[实验要求]
请参考《CPU设计实战》中的第五章和第六章，完成对现有CPU的运算指令、转移指令和访存指令的添加与测试，也就是lab6和lab7

[报告要求]
用latex编写实验报告
样式、章节安排参考D:\Architecture\lab1\report\report.tex

[本机环境]
本机有Vivado2025、XeLatex编译器以及Visual Studio编译工具链、Python环境
关于常见事项，如开发环境版本问题，不必严格参考原书，根据本机做决定。
部件型号：xc7a200tfbg676-2

[实验内容]
(你只需要给出一份TODO.md)
(乘除法添加直接用IP核实现)

Lab6

完成本章的学习后，读者应能够完成以下实践任务：在 lab5 的 CPU 代码的基础上添加更多的指令，包括算术逻辑运算类指令 ADD、ADDI、SUB、SLTI、SLTIU、ANDI、ORI、XORI、SLLV、SRAV、SRLV，乘除运算类指令 MULT、MULTU、DIV、DIVU，以及乘除法配套的数据搬运指令 MFHI、MFLO、MTHI、MTLO。运行 lab6.zip 里的 func_lab6，要求成功通过仿真和上板验证。

为完成以上实践任务，需要参考的文档包括但不限于：
1）本章内容。
2）附录 C。

本实践任务的硬件环境沿用 CPU_CDE，软件环境使用 lab6.zip。lab6.zip 只包含软件编译环境（func_lab6）。fun_lab6 和 func_lab4 相比，加入了对前述的新加入指令的测试内容。

请参考下列步骤完成实践任务：
1）请先完成第4章的学习。
2）学习本章内容。
3）准备好 lab5 的实验环境和 CPU_CDE，该环境也会作为 lab6 的实验环境。
4）解压 lab6.zip，将 func_lab6 拷贝到 CPU_CDE/soft/ 目录里，与 func_lab4 同层次。
5）打开 cpu132_gettrace 工程（CPU_CDE/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr）。
6）对 cpu132_gettrace 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab6 的 coe（CPU_CDE/soft/func_lab6/obj/inst_ram.coe）。
7）运行 cpu132_gettrace 工程的仿真（进入仿真界面后，直接点击 run all 等待仿真运行完成），生成新的参考 Trace 文件 golden_trace.txt（CPU_CDE/cpu132_gettrace/golden_trace.txt）。注意，要等仿真运行完成，golden_trace.txt 才有完整的内容。
8）打开 myCPU 工程（CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr）。
9）对 myCPU 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab6 的 coe（CPU_CDE/soft/func_lab6/obj/inst_ram.coe）。
10）运行 myCPU 工程的仿真（进入仿真界面后，直接点击 run all），开始调试。
11）myCPU 仿真通过后，综合实现后生成比特流文件，进行上板验证（如果没有实验箱，请跳过这一步）。

Lab7

完成本章的学习后，希望读者能够完成以下实践任务：在 lab6 的 CPU 代码中添加更多的指令，包括转移指令 BGEZ、BGTZ、BLEZ、BLTZ、J、BLTZAL、BGEZAL、JALR，以及访存指令 LB、LBU、LH、LHU、LWL、LWR、SB、SH、SWL、SWR。运行 lab7.zip 里的 func_lab7，要求成功通过仿真和上板验证。

为完成以上实践任务，需要参考的文档包括但不限于：
1）本章内容。
2）附录 C。

本实践任务的硬件环境沿用 CPU_CDE，软件环境使用 lab7.zip。lab7.zip 只包含软件编译环境（func_lab7）。fun_lab7 和 func_lab6 相比，加入了对前述新加入指令的测试内容。

请参考下列步骤完成实践任务：
1）请先完成第5章的学习。
2）学习本章内容。
3）准备好 lab6 的实验环境和 CPU_CDE，该环境也会作为 lab7 的实验环境。
4）解压 lab7.zip，将 func_lab7/ 拷贝到 CPU_CDE/soft/ 目录里，与 func_lab6 同层次。
5）打开 cpu132_gettrace 工程（CPU_CDE/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr）。
6）对 cpu132_gettrace 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab7 的 coe（CPU_CDE/soft/func_lab7/obj/inst_ram.coe）。
7）运行 cpu132_gettrace 工程的仿真（进入仿真界面后，直接点击 run all 等待仿真运行完成），生成新的参考 Trace 文件 golden_trace.txt（CPU_CDE/cpu132_gettrace/golden_trace.txt）。注意，要等仿真运行完成，golden_trace.txt 才有完整的内容。
8）打开 myCPU 工程（CPU_CDE/mycpu_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr）。
9）对 myCPU 工程中的 inst_ram 进行重新定制，此时选择加载 func_lab7 的 coe（CPU_CDE/soft/func_lab7/obj/inst_ram.coe）。
10）运行 myCPU 工程的仿真（进入仿真界面后，直接点击 run all），开始调试。