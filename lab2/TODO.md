# 第5–6章：lab6 / lab7 待办

对照 `lab2/prompt.md`。只做这份清单；乘除法用 Vivado IP，不自己写阵列。

起点是 lab1 已做完前递的五级流水线：`lab1/lab3/CPU_CDE/mycpu_verify/rtl/myCPU`。
仿真、重定制 `inst_ram`、生成 `golden_trace.txt` 在 Vivado 2025 里做。器件 `xc7a200tfbg676-2`。没有实验箱则跳过上板。

软件已经在仓库里：`lab2/lab6/func_lab6`（42 个功能点）、`lab2/lab7/func_lab7`（68 个功能点）。
做 lab6 前拷到 `CPU_CDE/soft/func_lab6`，与 `func_lab4` 同级；lab7 再拷 `func_lab7`。
`cpu132_gettrace` 和 `mycpu_prj1` 的 `inst_ram` 都改载对应 `obj/inst_ram.coe`，参考工程 `run all` 跑完再拿 `golden_trace.txt`。

现有指令：`addu subu slt sltu and or xor nor sll srl sra addiu lui lw sw beq bne jal jr`。
译码在 `ID_stage.v`，运算在 `alu.v`（`alu_op` 12 位），访存写使能在 `EXE_stage.v` 里对 `sw` 固定 `4'hf`。
数据 RAM 按字寻址（`data_sram_addr[17:2]`），`wea[3:0]` 是小端字节写使能。

前递和 load-use 停顿保持不动。新指令只要读 `rs`/`rt`，就补进 `rs_need`/`rt_need`；只要写通用寄存器，就让 `gr_we` 和 `dest` 正确，旁路会跟着走。

## 0. lab6：算术、移位、乘除、HI/LO

`func_lab6` 在 lab4 的 23 项之后增加 n24–n42。先让 n1–n23 仍然通过，再加新指令。

### 译码（opcode / funct）

R 型 opcode = `000000`：

| 指令 | funct | 写寄存器 | 读寄存器 |
|---|---|---|---|
| ADD | `100000` | rd | rs, rt |
| SUB | `100010` | rd | rs, rt |
| SLLV | `000100` | rd | rt 被移，rs[4:0] 为移位数 |
| SRLV | `000110` | rd | 同上 |
| SRAV | `000111` | rd | 同上 |
| MULT | `011000` | 不写 GPR，写 HI/LO | rs, rt |
| MULTU | `011001` | 同上 | rs, rt |
| DIV | `011010` | 商进 LO，余数进 HI | rs, rt |
| DIVU | `011011` | 同上 | rs, rt |
| MFHI | `010000` | rd ← HI | 不读 GPR |
| MTHI | `010001` | HI ← rs | rs |
| MFLO | `010010` | rd ← LO | 不读 GPR |
| MTLO | `010011` | LO ← rs | rs |

I 型：

| 指令 | opcode | 立即数 |
|---|---|---|
| ADDI | `001000` | 符号扩展，结果写 rt |
| SLTI | `001010` | 符号扩展，有符号比较 |
| SLTIU | `001011` | **仍符号扩展**，但按无符号比较 |
| ANDI | `001100` | **零扩展** |
| ORI | `001101` | 零扩展 |
| XORI | `001110` | 零扩展 |

- [x] ADD / ADDI / SUB 走现有加法器，与 ADDU / ADDIU / SUBU 同一条 `alu_op[0]` 或 `alu_op[1]`。本实验没有例外通路，不实现溢出例外；功能测试只对写回结果。
- [x] SLTI 复用 `slt`，SLTIU 复用 `sltu`。SLTIU 的立即数不要零扩展。
- [x] ANDI / ORI / XORI 复用 and/or/xor，但 `src2` 必须零扩展。现有 `src2_is_imm` 是符号扩展，给这三条单独加一个控制位，不要改 ADDIU/LW/SW 的扩展。
- [x] SLLV / SRLV / SRAV 复用现有移位。`src1_is_sa` 只留给 `sll/srl/sra`；变量移位的 `src1` 用 rs，`src2` 用 rt。移位数取低 5 位，ALU 里已经是 `alu_src1[4:0]`。
- [x] 新指令的 `rs_need`/`rt_need`、`dst_is_rt`、`gr_we` 补全。MULT/DIV/MTHI/MTLO/分支/store 不写 GPR。

### 乘除法 IP

- [x] 在 Vivado 里生成两个乘法器 IP 或一个可切换符号的核：MULT 有符号、MULTU 无符号，32×32→64。再生成除法器：DIV 有符号、DIVU 无符号。用 IP 的握手（`tvalid/tready` 或 `nd/rdy`，以生成界面为准），不要手写 Booth。
- [x] 乘除在 EX 做。结果没出来时 `es_ready_go = 0`，整条流水停住，不要同时发射第二条乘除。
- [x] 完成时 HI = 积[63:32] 或余数，LO = 积[31:0] 或商。有符号除法的余数符号与被除数相同；若 IP 余数符号相反，在写 HI 前改过来。除零结果无定义，测试不会除零。
- [x] HI/LO 用一对寄存器。MFHI/MFLO 在 EX 读出后作为该指令的写回数据（不要当 ALU 结果）。MTHI/MTLO 用 rs 覆盖 HI 或 LO。
- [x] 相邻的 MULT 后 MFLO、MTHI 后 MFHI：因为 EX 在乘除期间不放行，消费者要等写完 HI/LO 再进 EX。若 MF 与 MT 同拍读到旧值，再对 HI/LO 做一拍阻塞或旁路。`dest==0` 的 MF 不写寄存器堆。

### lab6 验证

- [x] `func_lab6` 的 coe 装进两个工程，重新生成 `golden_trace.txt`。
- [x] `mycpu` `run all`，42 个功能点通过。先看第一次不一致的 PC 落在 n24–n42 的哪一条。
- [x] 留波形：一条 ANDI（零扩展和符号扩展结果不同）、一条 SLTIU（负数立即数按无符号比）、一次 MULT 停住 EX 直到 HI/LO 更新、紧跟着的 MFLO。
- [ ] 上板可跳过。

## 1. lab7：转移和访存

在 lab6 通过之后做。`func_lab7` 增加 n43–n68，每条转移另有 `_ds` 延迟槽测试。

### 转移

延迟槽保持现有行为：分支在 ID 判定，IF 里已经取到的下一条照常执行，再下一拍从目标取指。判定用旁路后的 `rs_value`。目标基址与现有 `beq/bne` 相同（现在是 `fs_pc + offset`，顺序流动时 `fs_pc = ds_pc+4`）。`_ds` 失败时，再把全部 PC 相对分支统一改成 `ds_pc + 4 + offset`。

| 指令 | 编码 | 条件 | 链接 |
|---|---|---|---|
| J | opcode `000010` | 无条件 | 不写 |
| BGEZ | opcode `000001`，rt=`00001` | rs ≥ 0 | 不写 |
| BLTZ | opcode `000001`，rt=`00000` | rs < 0 | 不写 |
| BGEZAL | opcode `000001`，rt=`10001` | rs ≥ 0 | **无论是否跳转都写 $31 = PC+8** |
| BLTZAL | opcode `000001`，rt=`10000` | rs < 0 | 同上 |
| BGTZ | opcode `000111`，rt=0 | rs > 0 | 不写 |
| BLEZ | opcode `000110`，rt=0 | rs ≤ 0 | 不写 |
| JALR | opcode `000000`，funct `001001` | 无条件，目标 = rs | rd = PC+8，rd 默认 31；rd=0 不写 |

- [x] J 的目标与 JAL 相同：`{pc[31:28], instr_index, 2'b0}`，但不写 $31。
- [x] BGEZAL/BLTZAL/JALR 的返回地址复用 JAL 的 PC+8（`src1_is_pc`、`src2_is_8`）。链接写寄存器在分支不成立时也要发生。
- [x] JALR 不要和 JR（funct `001000`，且 rt=rd=sa=0）译成同一条。
- [x] `br_taken` 仍与 `ds_valid && ds_ready_go` 相与，相关没解开时不要改 PC。
- [x] 这些分支都读 rs，BEQ/BNE 已经读 rt。补 `rs_need`。

### 访存

地址仍是 `base + sign_extend(offset)`，按字节地址。RAM 用 `addr[17:2]` 选字，`addr[1:0]` 选字节。小端：`wen[0]` 对应 `[7:0]`。

读指令在 MEM 从返回的字里抽出字节/半字再扩展，写回 GPR。写指令只打开对应 `wen`，`wdata` 放到对应字节，其余字节重复同一半字/字节即可（没打开的 `wen` 不会写入）。

| 指令 | opcode | 行为 |
|---|---|---|
| LB | `100000` | 符号扩展字节 |
| LBU | `100100` | 零扩展字节 |
| LH | `100001` | 符号扩展半字，地址半字对齐 |
| LHU | `100101` | 零扩展半字 |
| LWL | `100010` | 见下表，要和 rt 的旧值拼接 |
| LWR | `100110` | 同上 |
| SB | `101000` | 写 1 字节 |
| SH | `101001` | 写半字 |
| SWL | `101010` | 见下表 |
| SWR | `101110` | 见下表 |

小端 LWL（mem 是读回的 32 位字，rt 是指令里的旧值）：

| addr[1:0] | 写入 rt |
|---|---|
| 0 | `{mem[7:0], rt[23:0]}` |
| 1 | `{mem[15:0], rt[15:0]}` |
| 2 | `{mem[23:0], rt[7:0]}` |
| 3 | `mem[31:0]` |

小端 LWR：

| addr[1:0] | 写入 rt |
|---|---|
| 0 | `mem[31:0]` |
| 1 | `{rt[31:24], mem[31:8]}` |
| 2 | `{rt[31:16], mem[31:16]}` |
| 3 | `{rt[31:8], mem[31:24]}` |

小端 SWL（只打开对应字节的 wen）：

| addr[1:0] | 写入内存 |
|---|---|
| 0 | mem[7:0] = rt[31:24] |
| 1 | mem[15:0] = rt[31:16] |
| 2 | mem[23:0] = rt[31:8] |
| 3 | mem[31:0] = rt |

小端 SWR：

| addr[1:0] | 写入内存 |
|---|---|
| 0 | mem[31:0] = rt |
| 1 | mem[31:8] = rt[23:0] |
| 2 | mem[31:16] = rt[15:0] |
| 3 | mem[31:24] = rt[7:0] |

- [x] `load_op` 覆盖全部 load。load-use 仍停一拍，下一拍从 MEM 前递。LB/LBU/LH/LHU 的扩展在 MEM 做完再送 `ms_final_result`，旁路出去的必须是扩展后的值。
- [x] LWL/LWR 同时读 rt。`rt_need = 1`，拼接用 ID 读出并锁存下来的 rt（含旁路）。不要在 MEM 再读一次寄存器堆。
- [x] SB/SH/SWL/SWR 读 rt 作为写数据，读 rs 作为基址。`mem_we` 不能再是 1 位全字写；把字节掩码一路传到 `data_sram_wen`。
- [x] 现有 LW/SW 行为不变：`wen = 4'hf`，地址低 2 位为 0。

### lab7 验证

- [x] 换成 `func_lab7` 的 coe，重新生成 `golden_trace.txt`。
- [x] 68 个功能点通过。延迟槽失败先查 `br_taken` 和目标基址；LWL/LWR 失败先对一张非对齐地址的拼接表。
- [x] 留波形：一条不成立的 BLTZAL（$31 仍被写成 PC+8，PC 不跳）、一条成立的 BGEZ 及其延迟槽、一次非对齐 LWL+LWR 拼回原字、一次 SB 只改一个字节。
- [ ] 上板可跳过。

## 2. 报告

lab6、lab7 都仿真通过后再写。新建 `lab2/report/report.tex`，章节对齐 `lab1/report/report.tex`（封面、目标、原理、实现、关键代码、结果、收获、源码目录）。

- [x] 原理只写本次新增的三件事：立即数两种扩展、HI/LO 与多周期乘除、部分字访存和非对齐拼接。前递原理不要再写一遍。
- [x] 关键代码贴译码新增、HI/LO 写回、`data_sram_wen` 和 LWL/LWR 拼接，不要把五个 stage 全贴进去。
- [x] 结果用上面留下的波形，并写明 func_lab6 42 项、func_lab7 68 项的结束时间。
- [x] 用 XeLaTeX 编译。
