# -*- coding: utf-8 -*-
import os

os.environ.setdefault("MPLBACKEND", "Agg")

from plot_vcd import Callout, GREEN, RED, draw

BASE = r"d:\Architecture\lab1\report\fig"

draw(
    BASE + r"\bug2.vcd",
    BASE + r"\bug2_wdata_x.png",
    "ds_valid 修复后，第一条写回数据为 X",
    1980, 2120,
    callouts=[
        Callout("debug_wb_pc", 2.070, "PC 正确", color=GREEN, ha="left", dx=0.006),
        Callout("debug_wb_rf_wdata", 2.070, "写回 X", color=RED, ha="left", dx=0.010),
        Callout("debug_wb_err", 2.067, "err 拉高", color=RED, ha="left", dx=0.010,
                point_y=0.55),
    ],
)

draw(
    BASE + r"\bug3.vcd",
    BASE + r"\bug3_addiu.png",
    "load_op 修复后，addiu 写成 fffffffe",
    1980, 2120,
    callouts=[
        Callout("debug_wb_rf_wdata", 2.070, "fffffffe ≠ ffffffff", color=RED,
                ha="left", dx=0.010),
        Callout("debug_wb_err", 2.067, "err 拉高", color=RED, ha="left", dx=0.010,
                point_y=0.55),
    ],
)

draw(
    BASE + r"\bug4.vcd",
    BASE + r"\bug4_branch.png",
    "ALU 端口修复后，beq 没有跳转",
    1980, 2160,
    callouts=[
        Callout("debug_wb_rf_wdata", 2.070, "第一条正确", color=GREEN, ha="left",
                dx=0.008),
        Callout("debug_wb_pc", 2.110, "未跳转 bfc00010", color=RED, ha="left",
                dx=0.006),
        Callout("debug_wb_err", 2.107, "err 拉高", color=RED, ha="left", dx=0.010,
                point_y=0.55),
    ],
)

draw(
    BASE + r"\bug5.vcd",
    BASE + r"\bug5_srl.png",
    "srl 写回丢掉最高位",
    888480, 888650,
    callouts=[
        Callout("debug_wb_rf_wdata", 888.540, "2dff20c0 ≠ adff20c0", color=RED,
                ha="left", dx=0.012),
        Callout("debug_wb_err", 888.537, "err 拉高", color=RED, ha="left", dx=0.012,
                point_y=0.55),
    ],
)
print("zooms done")
