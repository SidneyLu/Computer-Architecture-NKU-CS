### 8.5.1 实践任务一：添加类 SRAM 总线支持
本实践任务有以下两个要求：
1）将 CPU 顶层接口修改为类 SRAM 总线接口。
2）在 CPU_CDE_SRAM 环境里完成随机延迟的 func_lab9 功能验证。

本实践任务的环境不再沿用 lab3～lab9 的 CPU_CDE，而是使用类 SRAM 接口的 CPU 设计实验开发环境 CPU_CDE_SRAM，见 lab10.zip。CPU_CDE_SRAM 环境的使用方法与 CPU_CDE 环境基本一致，目录结构稍有不同，如下所示。
```
|-cpu132_gettrace/        该目录与 CPU_CDE 相同
|-soft/                   该目录与 CPU_CDE 相同
|-mycpu_sram_verify/      读者实现的类 SRAM 总线 CPU 的验证环境，与 CPU_CDE 大部分类似
|  |--rtl/
|  |  |--soc_sram_lite_top.v  SoC_lite 的顶层文件
|  |  |--myCPU/*         自己实现的 CPU 的 RTL 代码
|  |  |--CONFREG/        confreg 模块，用于访问 CPU 与开发板上数码管、拨码开关等外设
|  |  |--BRIDGE/         1×2 的桥接模块，CPU 的 data sram 接口同时访问 confreg 和 data_ram
|  |  |--ram_wrap/       以类 SRAM 接口封装的 RAM 模块
|  |  |--xilinx_ip/      定制的 Xilinx IP，包含 clk_pll、inst_ram、data_ram
|  |  |--testbench/      功能仿真验证平台
|  |  |--mycpu_tb.v      功能仿真顶层，该模块会抓取 debug 信息与 golden_trace.txt 进行比较
|  |--run_vivado/        Vivado 工程的运行目录
|  |  |--soc_lite.xdc    Vivado 工程设计的约束文件
|  |  |--mycpu_prj1/     创建的第一个 Vivado 工程，名字为 mycpu_prj1
|  |  |--*.xpr           Vivado 创建的工程文件，可直接打开
|  |  |--*               创建的其他 Vivado 工程
```

请参考下列步骤完成本实践任务：
1）学习 8.1 节、8.2 节的内容，重点理解类 SRAM 总线协议。
2）将 lab10.zip 解压到路径上无中文字符的目录里，环境为 CPU_CDE_SRAM。
3）解压 lab9 提供的 lab9.zip，将 func_lab9/ 拷贝到 CPU_CDE_SRAM/soft/ 目录里。
4）打开 cpu132_gettrace 工程（CPU_CDE_SRAM/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr）。
5）重新定制 cpu132_gettrace 工程中的 inst_ram，此时选择加载 func_lab9 的 coe（CPU_CDE_SRAM/soft/func_lab9/obj/inst_ram.coe）。
6）运行 cpu132_gettrace 工程的仿真（进入仿真界面后，直接点击 run all 等待仿真运行完成），生成新的参考 Trace 文件 golden_trace.txt（CPU_CDE_SRAM/cpu132_gettrace/golden_trace.txt）。注意，要等仿真运行完成后，golden_trace.txt 才有完整的内容。
7）编写 RTL 代码，将 lab9 完成的 myCPU 顶层接口调整为类 SRAM 总线接口。
8）将新完成的 myCPU 代码放在 CPU_CDE_SRAM/mycpu_sram_verify/rtl/myCPU/ 目录里。
9）打开 myCPU 工程（CPU_CDE_SRAM/mycpu_sram_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr）。
10）通过 “Add Sources” 将新的 myCPU 源码添加到工程中。
11）对 myCPU 工程中的 axi_ram 进行重新定制，此时选择加载 func_lab9 的 coe（CPU_CDE_SRAM/soft/func_lab9/obj/inst_ram.coe）。
12）运行 myCPU 工程的仿真（进入仿真界面后，直接点击 run all），开始调试。

206 CPU 设计实战

---

### 8.5.2 实践任务二：添加 AXI 总线支持
本实践任务的要求如下：
1）将 CPU 顶层接口修改为 AXI 总线接口。CPU 对外只有一个 AXI 接口，需在内部完成取指和数据访问的仲裁。推荐在本任务中实现一个类 SRAM-AXI 的 2×1 的转接桥，然后拼接上实践任务一完成的类 SRAM 接口的 CPU，将 myCPU 封装为 AXI 接口。
2）在 CPU_CDE_AXI 环境里完成固定延迟的 func_lab9 功能验证。

本实践任务的环境既不是 lab3～lab9 的 CPU_CDE，也不是 lab10 的 CPU_CDE_SRAM，而是使用 AXI 接口的 CPU 设计实验开发环境 CPU_CDE_AXI，见 lab11.zip。CPU_CDE_AXI 环境的使用方法与 CPU_CDE 环境基本一致，目录结构稍有不同，如下所示。
```
|-cpu132_gettrace/        该目录与 CPU_CDE 相同
|-soft/                   该目录与 CPU_CDE 相同
|-mycpu_axi_verify/       读者实现的类 SRAM 总线 CPU 的验证环境，与 CPU_CDE 大部分类似
|  |--rtl/
|  |  |--soc_axi_lite_top.v  SoC_lite 的顶层文件
|  |  |--myCPU/*         自己实现的 CPU 的 RTL 代码
|  |  |--CONFREG/        confreg 模块，用于访问 CPU 与开发板上数码管、拨码开关等外设
|  |  |--ram_wrap/       以支持随机延迟访问封装的 AXI RAM 模块
|  |  |--axi_wrap/       AXI 的 1×1 转接口，连接 CPU 和 Crossbar，用于抹平仿真和上板的差异
|  |  |--xilinx_ip/      定制的 Xilinx IP，包含 clk_pll、axi_ram 和 axi_crossbar_1x2
|  |  |--testbench/      功能仿真验证平台
|  |  |--mycpu_tb.v      功能仿真顶层，该模块会抓取 debug 信息与 golden_trace.txt 进行比较
|  |--run_vivado/        Vivado 工程的运行目录
|  |  |--soc_lite.xdc    Vivado 工程设计的约束文件
|  |  |--mycpu_prj1/     创建的第一个 Vivado 工程，名字为 mycpu_prj1
|  |  |--*.xpr           Vivado 创建的工程文件，可直接打开
|  |  |--*               创建的其他 Vivado 工程
```

请参考下列步骤完成本实践任务：
1）请先完成本章的实践任务一。
2）学习 8.3 节、8.4 节内容，重点理解 AXI 总线协议的内容。
3）将 lab11.zip 解压到路径上无中文字符的目录里，实验环境为 CPU_CDE_AXI。
4）解压 lab9 提供的 lab9.zip，将 func_lab9/ 拷贝到 CPU_CDE_AXI/soft/ 目录里。
5）打开 cpu132_gettrace 工程（CPU_CDE_AXI/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr）。
6）对 cpu132_gettrace 工程中的 inst_ram 重新定制，此时选择加载 func_lab9 的 coe（CPU_CDE_AXI/soft/func_lab9/obj/inst_ram.coe）。
7）运行 cpu132_gettrace 工程的仿真（进入仿真界面后，直接点击 run all 等待仿真运行完成），生成新的参考 Trace 文件 golden_trace.txt（CPU_CDE_SRAM/cpu132_gettrace/golden_trace.txt）。注意，要等仿真运行完成后，golden_trace.txt 才有完整的内容。
8）编写 RTL 代码，将 lab10 完成的 myCPU 顶层接口包装成 AXI 接口。（推荐本任务中实现一个 “类 SRAM-AXI” 的 2×1 的转接桥，然后拼接上实践任务一（也就是 lab11）完成的类 SRAM 接口的 CPU，将 myCPU 封装为 AXI 接口。）
9）将新完成的 myCPU 代码放在 CPU_CDE_AXI/mycpu_sram_verify/rtl/myCPU/ 目录里。
10）打开 myCPU 工程（CPU_CDE_AXI/mycpu_sram_verify/run_vivado/mycpu_prj1/mycpu_prj1.xpr）。
11）通过 “Add Sources” 将新的 myCPU 源码添加到工程中。
12）对 myCPU 工程中的 axi_ram 进行重新定制，此时选择加载 func_lab9 的 coe（CPU_CDE_AXI/soft/func_lab9/obj/inst_ram.coe）。
13）运行 myCPU 工程的仿真（进入仿真界面后，直接点击 run all），开始调试。

---

### 8.5.3 实践任务三：完成 AXI 随机延迟验证
本实践任务的要求如下：使实践任务二中完成的添加 AXI 总线接口的 CPU 能通过随机延迟验证。

本实践任务的环境与实践任务二（也就是 lab11）相同。

请参考下列步骤完成本实践任务：
1）请先完成本章的实践任务二。
2）准备好 lab11 的实验环境 CPU_CDE_AXI。
3）修改 CPU_CDE_SRAM/rtl/CONFREG/confreg.v 里的宏 RANDOM_SEED 的定义值，改为其他初始值，随后进行仿真和调试。
4）重复第 3 步多次，要求宏 RANDOM_SEED 的修改值能覆盖本章前面介绍的三种随机延迟类型。