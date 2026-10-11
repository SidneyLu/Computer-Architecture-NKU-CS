# -*- coding: utf-8 -*-
import os

os.environ.setdefault("MPLBACKEND", "Agg")

from plot_vcd import Callout, GREEN, ORANGE, RED, draw

BASE = r"d:\Architecture\lab1\report\fig"
NAMES = [
    "ds_ready_go",
    "ds_pc",
    "rs_value",
    "es_dest",
    "debug_wb_pc",
    "debug_wb_rf_wnum",
    "debug_wb_rf_wdata",
    "debug_wb_err",
]

# stall_before: addiu $s0,$s0,1 at ds_pc=bfc408b0 reads X (2505 ns),
# writeback X at 2535 ns, debug_wb_err rises at 2537 ns.
draw(
    BASE + r"\stall_before.vcd",
    BASE + r"\stall_before.png",
    "未阻塞：addiu $s0,$s0,1 读到 X",
    2480, 2580, NAMES,
    callouts=[
        Callout("ds_pc", 2.510, "addiu @ bfc408b0", color=RED, ha="left", dx=0.008),
        Callout("rs_value", 2.510, "ID 读到 X", color=RED, ha="right", dx=-0.006),
        Callout("debug_wb_rf_wdata", 2.540, "写回 X", color=RED, ha="right", dx=-0.006),
        Callout("debug_wb_err", 2.537, "err 拉高", color=RED, ha="left", dx=0.008,
                point_y=0.55),
    ],
)

# stall_after: 1-cycle stall at 2505 ns while ds_pc stays on bfc408b0;
# rs_value becomes 0 at 2515 ns; writeback 1 at 2545 ns; err stays 0.
draw(
    BASE + r"\stall_after.vcd",
    BASE + r"\stall_after.png",
    "阻塞后：ds_ready_go 拉低，写回 1",
    2480, 2720, NAMES,
    callouts=[
        Callout("ds_ready_go", 2.510, "阻塞", color=ORANGE, ha="right", dx=-0.012,
                point_y=0.12),
        Callout("ds_ready_go", 2.585, "阻塞", color=ORANGE, ha="center",
                point_y=0.12),
        Callout("ds_ready_go", 2.625, "阻塞", color=ORANGE, ha="left", dx=0.010,
                point_y=0.12),
        Callout("ds_pc", 2.515, "停留 bfc408b0", color=ORANGE, ha="left", dx=0.012),
        Callout("rs_value", 2.530, "rs_value=0", color=GREEN, ha="left", dx=0.010,
                point_y=0.50),
        Callout("debug_wb_rf_wdata", 2.550, "写回 1", color=GREEN, ha="left", dx=0.008),
        Callout("debug_wb_err", 2.600, "err 保持 0", color=GREEN, ha="center",
                point_y=0.08),
    ],
)
print("done")
