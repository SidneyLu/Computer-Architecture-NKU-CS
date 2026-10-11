# -*- coding: utf-8 -*-
import os

os.environ.setdefault("MPLBACKEND", "Agg")

from plot_vcd import Callout, GREEN, ORANGE, draw

BASE = r"d:\Architecture\lab1\report\fig"
VCD = BASE + r"\fwd.vcd"

# addu $v0 at es_pc=bfc6de24, bne $v0,$v1 at ds_pc=bfc6de28 ~14.755 us
# rs_value = es_alu_result = 6cbc4bde; ds_ready_go stays 1.
draw(
    VCD,
    BASE + r"\fwd_ex.png",
    "EX 前递：addu 在 EX，bne 的 rs_value 等于 ALU 结果",
    14730, 14790,
    [
        "ds_ready_go",
        "ds_pc",
        "rs_value",
        "es_alu_result",
        "es_dest",
        "es_pc",
        "debug_wb_err",
    ],
    callouts=[
        Callout("ds_ready_go", 14.760, "无阻塞", color=GREEN, ha="center",
                point_y=0.92),
        Callout("ds_pc", 14.760, "bne", color=GREEN, ha="left", dx=0.004),
        Callout("rs_value", 14.760, "EX 前递", color=GREEN, ha="left", dx=0.004,
                point_y=0.88),
        Callout("es_pc", 14.760, "addu", color=GREEN, ha="left", dx=0.004),
    ],
)

# wait_1s: lw $t2 then xor $t2,$t2,$t1. ds_ready_go low 14.385-14.395 us;
# next cycle rs_value = ms_final_result = aaaa.
draw(
    VCD,
    BASE + r"\fwd_load.png",
    "load-use：xor 停一拍，下一拍从 MEM 取得 lw 数据",
    14360, 14420,
    [
        "ds_ready_go",
        "ds_pc",
        "es_load_op",
        "es_valid",
        "rs_value",
        "ms_final_result",
        "ms_dest",
        "debug_wb_err",
    ],
    callouts=[
        Callout("ds_ready_go", 14.390, "load-use 阻塞", color=ORANGE, ha="right",
                dx=-0.004, point_y=0.12),
        Callout("rs_value", 14.400, "MEM 前递 aaaa", color=GREEN, ha="left", dx=0.004,
                point_y=0.88),
    ],
)
print("done")
