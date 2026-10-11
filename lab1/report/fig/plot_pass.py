# -*- coding: utf-8 -*-
import os

os.environ.setdefault("MPLBACKEND", "Agg")

from matplotlib.patheffects import withStroke
import matplotlib.pyplot as plt

from plot_vcd import GREEN, escape_title

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimSun"]
plt.rcParams["axes.unicode_minus"] = False

HALO = [withStroke(linewidth=2.4, foreground="white")]

pc_id = None
err_id = None
t = 0
pc_t, pc_y = [], []
err_t, err_y = [], []
in_def = True
with open(r"d:\Architecture\lab1\report\fig\pass.vcd", encoding="utf-8", errors="replace") as handle:
    for raw in handle:
        line = raw.strip()
        if not line:
            continue
        if line.startswith("$var"):
            parts = line.split()
            if parts[4] == "debug_wb_pc":
                pc_id = parts[3]
            elif parts[4] == "debug_wb_err":
                err_id = parts[3]
        elif line.startswith("$enddefinitions"):
            in_def = False
        elif in_def or line.startswith("$"):
            continue
        elif line.startswith("#"):
            t = int(line[1:]) / 1e9  # ps -> ms
        elif line[0] == "b" and pc_id and line.endswith(" " + pc_id):
            bits = line[1:line.rfind(" ")]
            if "x" not in bits and "z" not in bits:
                pc_t.append(t)
                pc_y.append(int(bits, 2) & 0xFFFFF)
        elif err_id and line[0] in "01" and line[1:] == err_id:
            err_t.append(t)
            err_y.append(int(line[0]))

fig, axes = plt.subplots(2, 1, sharex=True, figsize=(7.2, 3.8), dpi=200)
fig.subplots_adjust(left=0.16, right=0.98, top=0.84, bottom=0.16, hspace=0.28)
axes[0].plot(pc_t, pc_y, color="#1f4e79", lw=0.6)
axes[0].set_ylabel("PC[19:0]")
axes[0].set_title(escape_title("修复后，func_lab3 在 1.728 ms 结束并通过"), fontsize=11)
end_ms = 1.728
if pc_t:
    ymax = max(pc_y) * 1.08
    axes[0].set_ylim(min(0, min(pc_y)), ymax)
    axes[0].axvline(end_ms, color=GREEN, ls="--", lw=0.9, zorder=3)
    axes[0].annotate(
        "测试结束",
        xy=(end_ms, ymax * 0.55),
        xytext=(end_ms - 0.38, ymax * 0.78),
        arrowprops=dict(arrowstyle="-|>", color=GREEN, lw=1.2, mutation_scale=9),
        fontsize=7.5, color=GREEN, ha="right", va="bottom",
        clip_on=False, annotation_clip=False, path_effects=HALO,
    )
axes[1].step(err_t or [0, end_ms], err_y or [0, 0], where="post", color=GREEN, lw=1.35)
axes[1].set_ylabel("debug_wb_err")
axes[1].set_ylim(-0.25, 1.45)
axes[1].set_xlabel("时间 / ms")
axes[1].annotate(
    "err 保持 0",
    xy=(0.85, 0.05),
    xytext=(0.85, 0.95),
    arrowprops=dict(arrowstyle="-|>", color=GREEN, lw=1.2, mutation_scale=9),
    fontsize=7.5, color=GREEN, ha="center", va="bottom",
    clip_on=False, annotation_clip=False, path_effects=HALO,
)
for axis in axes:
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)
    axis.tick_params(labelsize=7.5)
fig.savefig(r"d:\Architecture\lab1\report\fig\pass_10ms.png", dpi=200)
plt.close(fig)
print("points", len(pc_t), "end", pc_t[-1] if pc_t else None)
