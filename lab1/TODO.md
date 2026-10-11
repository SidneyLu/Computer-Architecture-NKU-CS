# 第4章 简单流水线 CPU：待办

对照 `lab1/prompt.md` 与当前 RTL。源码在 `lab1/lab3/CPU_CDE/mycpu_verify/rtl/myCPU`。
仿真、看波形、重定制 `inst_ram` 自己在 Vivado 里做。器件 `xc7a200tfbg676-2`，Vivado 2025 打开 2019.2 工程时按书 4.3.3 升级工程和 IP。没有实验箱则跳过上板。

当前只有 `soft/func_lab3`。测试宏在相关指令之间插入了 `NOP4`（`include/cpu_cde.h`），所以任务一修完 bug 后，这条轨迹不会暴露写后读。任务二、三需要去掉这些 NOP 的 `hmc_lab4`（`lab4.zip`），仓库里还没有。

## 0. 先看清现在这颗 CPU

五级：IF → ID → EX → MEM → WB，级间用 `valid / allowin / ready_go` 握手。

- 分支在 ID 判定。IF 里已经取到的下一条是延迟槽，会继续进 ID；`nextpc` 在下一拍切到目标。`n20_beq_ds` 到 `n23_jr_ds` 依赖这一点，不要把延迟槽冲掉。
- 寄存器在 ID 读、在 WB 的时钟沿写。`regfile.v` 没有写优先。
- `ds_ready_go`、`es_ready_go` 恒为 1。没有阻塞，也没有从 EX/MEM/WB 指回 ID 的数据通路。
- 相邻指令的距离：消费者在 ID 时，上一条在 EX，隔 1 条在 MEM，隔 2 条在 WB。WB 与 ID 同拍时，寄存器堆还是旧值。`NOP4` 把消费者推到写回之后，所以 `func_lab3` 看不出数据相关。

指令：`addu subu slt sltu and or xor nor sll srl sra addiu lui lw sw beq bne jal jr`。

## 1. 任务一：修 bug，跑通 func_lab3

书上写预置 7 处。下面是读源码就能确定的错误。用 `cpu132_gettrace` 已有的 `golden_trace.txt` 对 `mycpu_prj1`，以第一次 trace 不一致的 PC 为准，逐条销掉。译码器上界那条功能测试不一定撞得到，仍建议改。

- [x] `mycpu.h`：``define BR_BUS_WD 32`。`{br_taken, br_target}` 是 33 位，高位 `br_taken` 被截掉，IF 里解包后 `br_taken` 恒为 0，分支不会生效。改为 33。
- [x] `ID_stage.v`：`ds_valid` 只有声明，没有复位，也没有在 `ds_allowin` 时接收 `fs_to_ds_valid`。译码级有效位是 X。补上与 EX/MEM/WB 相同的 valid 更新。
- [x] `ID_stage.v`：`load_op` 未赋值。总线上送的是 `load_op`，而 `res_from_mem = inst_lw` 没有送出去，`lw` 写回会拿到 ALU 结果。`assign load_op = inst_lw;`
- [x] `ID_stage.v`：`beq/bne/jal` 的基址用了 IF 的 `fs_pc`。分支在 ID，基址应是本条指令的 `ds_pc`。顺序流动时 `fs_pc` 碰巧等于 `ds_pc+4`，前一条是跳转或流水线停住时就不对。`beq/bne` 按标准 MIPS 写成 `ds_pc + 4 + {{14{imm[15]}}, imm, 2'b0}`；`jal` 写成 `{ds_pc[31:28], jidx, 2'b0}`。只把 `fs_pc` 换成 `ds_pc` 而不加 4，目标会少一条指令。
- [x] `EXE_stage.v`：`alu` 的 `alu_src1`、`alu_src2` 都接了 `es_alu_src2`。`alu_src1` 改接 `es_alu_src1`。
- [x] `alu.v`：`or_result = alu_src1 | alu_src2 | alu_result`，组合环，`or/nor` 都不对。去掉 `| alu_result`。
- [x] `alu.v`：`sr_result = sr64_result[30:0]`，右移丢掉最高位。改为 `sr64_result[31:0]`。
- [x] `MEM_stage.v`：`es_to_ms_bus_r = es_to_ms_bus` 是阻塞赋值，和其他级的 `<=` 不一致，仿真会有竞争。改为非阻塞赋值。
- [x] `tools.v`：`decoder_6_64` 循环是 `i<63`，`out[63]` 悬空。改为 `i<64`。现有指令用不到 63，但不要留着。
- [x] 仿真 `run all`，trace 对比到结束。记录每个 bug 第一次错在哪条指令、波形上哪个信号不对。这是报告“任务一”的材料。
- [x] 上板可跳过。



## 2. 任务二：阻塞，解决写后读

在任务一通过之后做。不要在有 bug 的 RTL 上加阻塞。

- [x] 拿到 `hmc_lab4`，放到 `soft/` 下，与 `func_lab3` 同级。`cpu132_gettrace` 和 `mycpu_prj1` 的 `inst_ram` 都改载 `hmc_lab4` 的 coe，重新跑参考工程，生成新的 `golden_trace.txt`。
- [x] 在 ID 检测相关：本条要用的 `rs`/`rt`（写寄存器类两条都看；`sw` 看基址和存数；`beq/bne/jr` 看比较或跳转寄存器；目的寄存器为 0 不算）。
- [x] 命中 EX、MEM、WB 的写寄存器（`valid && gr_we && dest!=0`）时，`ds_ready_go = 0`。现有握手会停住 IF，并向 EX 送气泡。
- [x] WB 同拍读必须单独处理：只堵住 EX/MEM、放行 WB 的话，ID 仍读到旧值。二选一：WB 命中也停一拍，或在 `regfile` 加写优先（`we && raddr==waddr && waddr!=0` 时直接出 `wdata`）。报告里写清选了哪一种。
- [x] 用 `hmc_lab4` 跑到 trace 一致。抓一条相邻的 `addu` 和一条 `lw` 后紧跟使用的波形：停在哪几拍、气泡从哪一级推进、写回之后哪一拍才读对。记下总周期，留给任务三比较。



## 3. 任务三：前递，去掉多余气泡

仍用 `hmc_lab4`。在任务二的阻塞版本上改，保留 load-use 那种必须停的情况。

- [x] 画旁路图再写代码。操作数在 ID 读出后锁存进 EX，所以旁路接在 ID 的 `rs_value`/`rt_value` 上，分支比较和 `jr` 目标也用旁路后的值。优先级：EX 高于 MEM，高于 WB，高于寄存器堆。
- [x] EX 前递 ALU 结果；MEM 前递 `ms_final_result`（含已经返回的 load 数据）；WB 前递 `rf_wdata`，或继续用寄存器堆写优先。
- [x] load 在 EX 时数据还没回来。消费者已经在 ID，则仍令 `ds_ready_go = 0`，停一拍，下一拍从 MEM 前递。ALU 结果、已经在 MEM/WB 的 load，不再阻塞。
- [x] `dest==0` 不前递。store 的 `rt`、load/store 的基址、分支的两个源都要覆盖。
- [x] 仿真通过，且周期数明显少于纯阻塞。同一段指令各留一张波形：
  - 无处理：ID 读到旧值（任务一修完、尚未加冲突逻辑时，用一小段手写相关指令即可，不必等 lab4）
  - 只阻塞：多出来的气泡
  - 前递：EX→ID、MEM→ID 各一条；load-use 仍有一拍停顿
- [x] 上板可跳过。



## 4. 报告

框架在 `lab1/report/report.tex`，章节对齐 `example.tex`。封面补班号、授课教师、实验时间。

- [x] 用 XeLaTeX 编译，确认封面三栏和示意图能出来。
- [x] 填任务一的 bug 表：现象、错误代码、改法、改完波形。
- [x] 填阻塞与前递的波形和周期对比。示意图若和最终接线不一致，改 `report.tex` 里的 TikZ。
- [x] 关键代码只贴改过的 valid、阻塞条件和前递多路选择，不要把五个 stage 全贴进去。