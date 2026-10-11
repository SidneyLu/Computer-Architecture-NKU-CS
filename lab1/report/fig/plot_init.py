# -*- coding: utf-8 -*-
import os

os.environ.setdefault("MPLBACKEND", "Agg")

from matplotlib.patches import Rectangle
from matplotlib.patheffects import withStroke
import matplotlib.pyplot as plt

from plot_vcd import GREEN, RED, add_callout, escape_title

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimSun"]
plt.rcParams["axes.unicode_minus"] = False

HALO = [withStroke(linewidth=2.4, foreground="white")]

signals = [
    ("resetn", "bit"),
    ("ds_valid", "x"),
    ("debug_wb_pc", "x"),
    ("debug_wb_rf_wen", "x"),
    ("debug_wb_rf_wnum", "x"),
    ("debug_wb_rf_wdata", "x"),
    ("debug_wb_err", "zero"),
]

fig, axes = plt.subplots(len(signals), 1, sharex=True, figsize=(7.2, 6.2), dpi=200)
fig.subplots_adjust(left=0.26, right=0.985, top=0.84, bottom=0.11, hspace=0.36)

for axis, (name, kind) in zip(axes, signals):
    axis.set_xlim(0, 10)
    axis.set_ylim(-0.22, 1.78)
    axis.set_yticks([])
    axis.set_ylabel(name, rotation=0, ha="right", va="center", fontsize=8, labelpad=6)
    if kind == "bit":
        axis.plot([0, 0.002, 0.002, 10], [0, 0, 1, 1], color=GREEN, lw=1.35)
    elif kind == "zero":
        axis.plot([0, 10], [0, 0], color=GREEN, lw=1.35)
        axis.text(5, 0.50, "0", ha="center", va="center", fontsize=8, color=GREEN,
                  path_effects=HALO)
    else:
        axis.add_patch(Rectangle(
            (0, 0.15), 10, 0.70,
            facecolor="#f6d0cc", edgecolor="#a33b3b",
            hatch="///", linewidth=0.45, clip_on=False,
        ))
        axis.text(5, 0.50, "X", ha="center", va="center", fontsize=9, color="#7a1f1f",
                  path_effects=HALO)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)
    axis.tick_params(labelsize=7.5)

add_callout(axes[0], 0.002, "复位结束 2 µs", color=RED, ha="left", dx=0.55,
            point_y=0.55, text_y=1.38)
add_callout(axes[1], 3.2, "全程 X", color=RED, ha="center", point_y=0.88, text_y=1.38)
add_callout(axes[-1], 5.0, "err 保持 0", color=GREEN, ha="center",
            point_y=0.08, text_y=1.38)

axes[-1].set_xlabel("时间 / ms", fontsize=9)
axes[0].set_title(escape_title("修复前，仿真全长 0–10 ms"), fontsize=11)
fig.savefig(r"d:\Architecture\lab1\report\fig\bug1_10ms.png", dpi=200)
plt.close(fig)
print("wrote bug1_10ms.png")
