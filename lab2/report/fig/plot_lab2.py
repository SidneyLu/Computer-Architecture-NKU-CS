# -*- coding: utf-8 -*-
import os
import sys

os.environ.setdefault("MPLBACKEND", "Agg")
sys.path.insert(0, r"d:\Architecture\lab1\report\fig")

from plot_vcd import BIT_SIGNALS, Callout, GREEN, ORANGE, RED, draw

BIT_SIGNALS.update({"es_ready_go", "br_taken", "ds_ready_go"})

VCD = r"d:\Architecture\lab2\report\fig\cases.vcd"
OUT = r"d:\Architecture\lab2\report\fig"

draw(
    VCD, OUT + r"\sltiu.png",
    "sltiu $v0,$t0,-2967 写回 1",
    675620, 675700,
    ["es_pc", "ms_pc", "ms_final_result", "debug_wb_pc",
     "debug_wb_rf_wnum", "debug_wb_rf_wdata"],
    callouts=[
        Callout("es_pc", 675.630, "sltiu", color=ORANGE, ha="left", dx=0.004),
        Callout("ms_final_result", 675.640, "结果 1", color=GREEN, ha="left", dx=0.006,
                point_y=0.55),
        Callout("debug_wb_rf_wdata", 675.650, "写回 1", color=GREEN, ha="right", dx=-0.004),
    ],
)

draw(
    VCD, OUT + r"\andi.png",
    "andi $v0,$t0,0x5e89 零扩展",
    697050, 697120,
    ["es_pc", "debug_wb_pc", "debug_wb_rf_wnum", "debug_wb_rf_wdata"],
    callouts=[
        Callout("es_pc", 697.060, "andi", color=ORANGE, ha="left", dx=0.004),
        Callout("debug_wb_pc", 697.080, "bfc80c58", color=ORANGE, ha="left", dx=0.004),
        Callout("debug_wb_rf_wdata", 697.080, "4c80", color=GREEN, ha="right", dx=-0.004,
                point_y=0.55),
    ],
)

draw(
    VCD, OUT + r"\mult.png",
    "mult 停住 EX，随后 mflo",
    993640, 993760,
    ["es_pc", "es_ready_go", "hi", "lo",
     "debug_wb_pc", "debug_wb_rf_wnum", "debug_wb_rf_wdata"],
    callouts=[
        Callout("es_ready_go", 993.665, "停 2 拍", color=ORANGE, ha="left", dx=0.006,
                point_y=0.12),
        Callout("hi", 993.690, "HI", color=GREEN, ha="left", dx=0.008, point_y=0.55),
        Callout("lo", 993.690, "LO", color=GREEN, ha="right", dx=-0.006, point_y=0.55),
        Callout("debug_wb_rf_wdata", 993.710, "写回 a20a480", color=GREEN, ha="left", dx=0.004),
    ],
)

draw(
    VCD, OUT + r"\bgez.png",
    "bgez 成立：延迟槽后进入目标",
    1103005, 1103090,
    ["ds_pc", "es_pc", "debug_wb_pc"],
    callouts=[
        Callout("es_pc", 1103.020, "bgez", color=ORANGE, ha="left", dx=0.004),
        Callout("ds_pc", 1103.020, "延迟槽", color=ORANGE, ha="right", dx=-0.004),
        Callout("ds_pc", 1103.040, "目标 bfc60000", color=GREEN, ha="left", dx=0.006),
    ],
)

draw(
    VCD, OUT + r"\bltzal.png",
    "bltzal 不成立仍写 $31",
    1246635, 1246682,
    ["ds_pc", "br_taken", "es_pc", "debug_wb_pc",
     "debug_wb_rf_wnum", "debug_wb_rf_wdata"],
    callouts=[
        Callout("br_taken", 1246.650, "不跳", color=ORANGE, ha="left", dx=0.004,
                point_y=0.12),
        Callout("ds_pc", 1246.670, "顺序 bfc4069c", color=GREEN, ha="left", dx=0.006),
        Callout("debug_wb_rf_wnum", 1246.670, "$31", color=GREEN, ha="right", dx=-0.004,
                point_y=0.55),
        Callout("debug_wb_rf_wdata", 1246.670, "PC+8", color=GREEN, ha="left", dx=0.008),
    ],
)

draw(
    VCD, OUT + r"\lwr.png",
    "lwr 地址低两位为 1，拼回 ca5c0495",
    1545315, 1545400,
    ["es_pc", "data_sram_addr", "mem_word", "ms_rt_value",
     "ms_final_result", "debug_wb_rf_wdata"],
    callouts=[
        Callout("data_sram_addr", 1545.330, "800dbd99", color=ORANGE, ha="left", dx=0.004),
        Callout("mem_word", 1545.340, "5c049582", color=ORANGE, ha="right", dx=-0.004),
        Callout("ms_rt_value", 1545.340, "旧值 ca18f110", color=ORANGE, ha="left", dx=0.006,
                point_y=0.55),
        Callout("ms_final_result", 1545.340, "ca5c0495", color=GREEN, ha="right", dx=-0.004),
    ],
)

draw(
    VCD, OUT + r"\sb.png",
    "sb 只打开最低字节",
    1558405, 1558510,
    ["es_pc", "data_sram_wen", "data_sram_addr", "data_sram_wdata",
     "mem_word", "debug_wb_rf_wdata"],
    callouts=[
        Callout("data_sram_wen", 1558.420, "wen=1", color=ORANGE, ha="left", dx=0.006,
                point_y=0.55),
        Callout("data_sram_wdata", 1558.420, "0a 重复", color=ORANGE, ha="right", dx=-0.004),
        Callout("mem_word", 1558.430, "b4f0090a", color=GREEN, ha="left", dx=0.006),
        Callout("debug_wb_rf_wdata", 1558.490, "读回 b4f0090a", color=GREEN, ha="right", dx=-0.006),
    ],
)
print("done")
