# Figures for the memory-game round recorded in the passing simulation.
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyBboxPatch, Rectangle

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimHei", "DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False

OUT = r"D:\Architecture\lab3\report\fig"
os.makedirs(OUT, exist_ok=True)

PAT = [8, 8, 1, 2, 8, 2, 8, 2]
SHOW = [20437, 28569, 44717, 60865, 77013, 93161, 109309, 125457]
ECHO = [141641, 149793, 149965, 158144, 158280, 166459, 166604, 174783]
PRESS = [141539, 149717, 149853, 158041, 158204, 166356, 166519, 174680]
COLOR = {1: "#2f6fad", 2: "#2e8b57", 4: "#c47b00", 8: "#b5523a"}
LED = {8: 0xFFF7, 4: 0xFFFB, 2: 0xFFFD, 1: 0xFFFE}


def timeline():
    latency = [e - p for e, p in zip(ECHO, PRESS)]
    gap = [PRESS[i + 1] - ECHO[i] for i in range(7)] + [174843 - ECHO[7]]
    fig, axes = plt.subplots(2, 1, figsize=(8.4, 4.6), gridspec_kw={"height_ratios": [1, 1.35]})

    ax = axes[0]
    xs = [t / 1000 for t in SHOW]
    ax.plot(xs, [0] * 8, color="#dddddd", lw=2, zorder=1)
    for x, p in zip(xs, PAT):
        ax.scatter(x, 0, s=110, color=COLOR[p], zorder=3)
        ax.text(x, 0.18, str(p), ha="center", va="bottom", fontsize=9, color=COLOR[p])
    ax.set_yticks([])
    ax.set_xlim(15, 135)
    ax.set_ylim(-0.45, 0.7)
    ax.set_xlabel("出题时刻（拍 / 1000）")
    ax.set_title("出题顺序")
    ax.grid(True, axis="x", lw=0.3)

    ax = axes[1]
    idx = list(range(8))
    w = 0.36
    ax.bar([i - w / 2 for i in idx], latency, width=w, color="#4c78a8", label="按下到灯点亮")
    ax.bar([i + w / 2 for i in idx], gap, width=w, color="#f2a35a", label="灯点亮到下一次按下")
    for i, (lat, g) in enumerate(zip(latency, gap)):
        ax.text(i - w / 2, lat + 120, str(lat), ha="center", va="bottom", fontsize=7, color="#4c78a8")
        ax.text(i + w / 2, g + 120, str(g), ha="center", va="bottom", fontsize=7, color="#b86a22")
    ax.set_xticks(idx)
    ax.set_xticklabels(["%d\n图案 %d" % (i, p) for i, p in enumerate(PAT)])
    ax.set_ylabel("拍")
    ax.set_ylim(0, 10500)
    ax.legend(frameon=False, ncol=2, fontsize=8, loc="upper center", bbox_to_anchor=(0.5, -0.34))
    ax.set_title("回放：采样约 100 拍，间隔在 8076 拍和 60 拍之间交替")
    ax.grid(True, axis="y", lw=0.3)
    fig.tight_layout()
    path = os.path.join(OUT, "game_timeline.png")
    fig.savefig(path, dpi=140, bbox_inches="tight")
    plt.close(fig)
    print("wrote", path)


def lamps():
    fig, ax = plt.subplots(figsize=(8.4, 4.2))
    ax.set_xlim(-0.4, 8.6)
    ax.set_ylim(-1.55, 3.35)
    ax.axis("off")
    ax.set_title("出题时的灯和按键之后的灯", pad=8)
    ax.text(-0.25, 2.35, "出题", ha="right", va="center", fontsize=9)
    ax.text(-0.25, 0.85, "按键", ha="right", va="center", fontsize=9)
    for i, p in enumerate(PAT):
        for row, y in ((0, 2.35), (1, 0.85)):
            bit = {1: 0, 2: 1, 4: 2, 8: 3}[p]
            for b in range(4):
                on = b == bit
                c = Circle((i + 0.15 * (b - 1.5), y), 0.11,
                           facecolor=COLOR[p] if on else "#f4f4f4",
                           edgecolor=COLOR[p] if on else "#bbbbbb", lw=0.8)
                ax.add_patch(c)
        ax.text(i, 1.55, "相同", ha="center", va="center", fontsize=8, color="#1d6b3a")
        ax.text(i, 0.28, "灯 %04x" % LED[p], ha="center", va="center", fontsize=7, color="#444444")
        ax.text(i, 3.05, str(i), ha="center", va="center", fontsize=8, color="#666666")
    box = FancyBboxPatch((0.15, -1.35), 7.7, 0.85, boxstyle="round,pad=0.02,rounding_size=0.08",
                         facecolor="#f7f1e8", edgecolor="#c4b59a", lw=0.8)
    ax.add_patch(box)
    ax.text(4.0, -0.72, "SOC_NUM = 0x08000008", ha="center", va="center", fontsize=11)
    ax.text(2.3, -1.12, "高字节 0x08：已猜 8 次", ha="center", va="center", fontsize=8, color="#555555")
    ax.text(5.7, -1.12, "低字节 0x08：得分 8", ha="center", va="center", fontsize=8, color="#555555")
    fig.tight_layout()
    path = os.path.join(OUT, "game_match.png")
    fig.savefig(path, dpi=140)
    plt.close(fig)
    print("wrote", path)


timeline()
lamps()
