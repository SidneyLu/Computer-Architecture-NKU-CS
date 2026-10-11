# -*- coding: utf-8 -*-
"""Shared VCD waveform drawing for the lab report.

Bus labels are collision-aware: a hex string is drawn only when the
interval is wide enough and it does not overlap the previous label.
One-cycle pulses are not stuffed with hex; notable events use an
arrow + short callout above the lane instead.

VCD ``b0`` / ``b1`` on a multi-bit signal is treated as the integer
value 0 / 1, not as a 1-bit digital waveform.
"""
import os
import sys

os.environ.setdefault("MPLBACKEND", "Agg")

from dataclasses import dataclass
from matplotlib.patches import Rectangle
from matplotlib.patheffects import withStroke
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimSun"]
plt.rcParams["axes.unicode_minus"] = False
plt.rcParams["axes.titlepad"] = 10

BIT_SIGNALS = {
    "resetn",
    "ds_ready_go",
    "ds_valid",
    "debug_wb_err",
    "es_valid",
    "ms_valid",
    "rf_we",
    "es_load_op",
}

HALO = [withStroke(linewidth=2.4, foreground="white")]
BUS_FACE = "#d9e8f6"
BUS_EDGE = "#8aa7c1"
X_FACE = "#f6d0cc"
X_EDGE = "#a33b3b"
MARK_FACE = "#f8d4c4"
MARK_EDGE = "#c0392b"
GREEN_FACE = "#d5f0dc"
GREEN_EDGE = "#1b7f3a"
DIGITAL = "#1b7f3a"
TEXT_BUS = "#16324f"
RED = "#c0392b"
ORANGE = "#d35400"
GREEN = "#1b7f3a"

LEFT_FRAC = 0.26
RIGHT_FRAC = 0.985
# Clock is 10 ns; treat anything under ~1.4 clocks as a one-cycle pulse.
ONE_CYCLE_US = 0.014


@dataclass
class Callout:
    signal: str
    t_us: float
    text: str
    color: str = RED
    ha: str = "center"
    dx: float = 0.0
    point_y: float = 0.90
    text_y: float = 1.42


def parse_vcd(path, names=None):
    want = set(names) if names else None
    ids = {}
    waves = {}
    t = 0
    in_def = True
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.strip()
            if not line:
                continue
            if line.startswith("$var"):
                parts = line.split()
                name = parts[4]
                if want is None or name in want:
                    ids[parts[3]] = name
                    waves.setdefault(name, [])
            elif line.startswith("$enddefinitions"):
                in_def = False
            elif in_def:
                continue
            elif line.startswith("#"):
                t = int(line[1:])
            elif line[0] in "01xz":
                name = ids.get(line[1:])
                if name:
                    waves[name].append((t, line[0]))
            elif line[0] == "b":
                bits, ident = line[1:].split()
                name = ids.get(ident)
                if name:
                    waves[name].append((t, bits))
    return waves


def load_window(path, names, t0_ns, t1_ns):
    t0, t1 = int(float(t0_ns) * 1000), int(float(t1_ns) * 1000)
    ids = {}
    waves = {n: [] for n in names}
    t = 0
    in_def = True
    last = {n: "x" for n in names}
    seeded = False
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.strip()
            if not line:
                continue
            if line.startswith("$var"):
                parts = line.split()
                if parts[4] in waves:
                    ids[parts[3]] = parts[4]
            elif line.startswith("$enddefinitions"):
                in_def = False
            elif in_def or line.startswith("$"):
                continue
            elif line.startswith("#"):
                t = int(line[1:])
                if (not seeded) and t >= t0:
                    for n, v in last.items():
                        waves[n].append((t0, v))
                    seeded = True
                if t > t1:
                    break
            else:
                if line[0] == "b":
                    bits, ident = line[1:].split()
                    name = ids.get(ident)
                    if name:
                        last[name] = bits
                        if t0 <= t <= t1:
                            waves[name].append((t, bits))
                elif line[0] in "01xz":
                    name = ids.get(line[1:])
                    if name:
                        last[name] = line[0]
                        if t0 <= t <= t1:
                            waves[name].append((t, line[0]))
    if not seeded:
        for n, v in last.items():
            waves[n].append((t0, v))
    for n, v in last.items():
        if waves[n] and waves[n][-1][0] < t1:
            waves[n].append((t1, v))
        elif not waves[n]:
            waves[n].append((t0, v))
    return waves


def hex_of(bits):
    if bits is None or bits == "":
        return "X"
    if any(ch in "xz" for ch in str(bits).lower()):
        return "X"
    return format(int(bits, 2), "x")


def is_x(val):
    return val is None or any(ch in "xz" for ch in str(val).lower())


def is_bit(name):
    return name in BIT_SIGNALS


def escape_title(text):
    return text.replace("$", r"\$")


def merge_segments(pts, end_ps):
    if not pts:
        return []
    out = []
    t0, v0 = pts[0]
    for t, v in pts[1:]:
        if t <= t0:
            continue
        if v != v0:
            out.append((t0, t, v0))
            t0, v0 = t, v
    if t0 < end_ps:
        out.append((t0, end_ps, v0))
    elif not out:
        out.append((t0, end_ps, v0))
    return out


def text_width_us(text, fontsize, span_us, fig):
    axes_in = fig.get_figwidth() * (RIGHT_FRAC - LEFT_FRAC)
    char_in = (fontsize / 72.0) * 0.62
    return (max(len(text), 1) * char_in / max(axes_in, 0.5)) * span_us


def add_callout(axis, x_us, text, color=RED, ha="center", dx=0.0,
                point_y=0.90, text_y=1.42):
    axis.annotate(
        text,
        xy=(x_us, point_y),
        xytext=(x_us + dx, text_y),
        textcoords="data",
        arrowprops=dict(
            arrowstyle="-|>",
            color=color,
            lw=1.25,
            mutation_scale=9,
            shrinkA=1,
            shrinkB=1,
        ),
        fontsize=7.5,
        color=color,
        ha=ha,
        va="bottom",
        clip_on=False,
        annotation_clip=False,
        zorder=12,
        path_effects=HALO,
    )


def _mark_color(marks, x0, x1):
    for item in marks:
        t_us, color = item
        if x0 - 1e-6 <= t_us <= x1 + 1e-6:
            return color
    return None


def _draw_lane(axis, name, segs, span_us, fig, marks):
    last_right = None
    min_gap = text_width_us("00", 7, span_us, fig)
    for t0, t1, val in segs:
        x0, x1 = t0 / 1e6, t1 / 1e6
        width = x1 - x0
        low = str(val).lower()
        mcolor = _mark_color(marks, x0, x1)
        if is_bit(name) and low in ("0", "1") and not is_x(val):
            y = int(val)
            axis.plot([x0, x1], [y, y], color=DIGITAL, lw=1.35, solid_capstyle="butt")
            continue
        if is_x(val):
            edge = mcolor or X_EDGE
            axis.add_patch(Rectangle(
                (x0, 0.15), max(width, span_us * 1e-4), 0.70,
                facecolor=X_FACE, edgecolor=edge,
                hatch="///", linewidth=1.05 if mcolor else 0.35, zorder=2,
                clip_on=False,
            ))
            label = "X"
            fs = 8 if width > span_us * 0.08 else 7
        else:
            if mcolor == GREEN:
                face, edge = GREEN_FACE, GREEN_EDGE
            elif mcolor:
                face, edge = MARK_FACE, mcolor
            else:
                face, edge = BUS_FACE, BUS_EDGE
            axis.add_patch(Rectangle(
                (x0, 0.15), max(width, span_us * 1e-4), 0.70,
                facecolor=face, edgecolor=edge,
                linewidth=1.05 if mcolor else 0.35, zorder=2,
                clip_on=False,
            ))
            label = hex_of(val)
            fs = 7
        # One-cycle pulses: hatching / highlight + arrow, never hex in the box.
        if width < ONE_CYCLE_US:
            continue
        need = text_width_us(label, fs, span_us, fig)
        cx = (x0 + x1) / 2.0
        left = cx - need / 2.0
        if last_right is not None and left < last_right + min_gap:
            continue
        if width < need * 1.15:
            continue
        axis.text(
            cx, 0.50, label, ha="center", va="center",
            fontsize=fs, color=mcolor or (RED if is_x(val) else TEXT_BUS),
            zorder=4, clip_on=True, path_effects=HALO,
        )
        last_right = cx + need / 2.0


def draw(vcd, png, title, t_start_ns=None, t_end_ns=None, names=None,
         callouts=None, xlabel="时间 / µs"):
    if names is None:
        names = [
            "resetn",
            "debug_wb_pc",
            "debug_wb_rf_wen",
            "debug_wb_rf_wnum",
            "debug_wb_rf_wdata",
            "debug_wb_err",
        ]
    callouts = callouts or []
    if t_start_ns is None or t_end_ns is None:
        waves = parse_vcd(vcd, names)
        last = 0
        for name in names:
            if waves.get(name):
                last = max(last, waves[name][-1][0])
        start_ps = 0 if t_start_ns is None else int(float(t_start_ns) * 1000)
        end_ps = last if t_end_ns is None else int(float(t_end_ns) * 1000)
        for name in names:
            pts = waves.get(name) or [(start_ps, "x")]
            if pts[0][0] > start_ps:
                pts = [(start_ps, pts[0][1])] + pts
            waves[name] = pts
    else:
        waves = load_window(vcd, names, t_start_ns, t_end_ns)
        start_ps = int(float(t_start_ns) * 1000)
        end_ps = int(float(t_end_ns) * 1000)

    start_us = start_ps / 1e6
    end_us = end_ps / 1e6
    span = max(end_us - start_us, 1e-6)
    pad_right = span * 0.02
    n = len(names)
    fig, axes = plt.subplots(
        n, 1, sharex=True,
        figsize=(7.2, 0.82 * n + 1.45), dpi=200,
    )
    if n == 1:
        axes = [axes]
    fig.subplots_adjust(
        left=LEFT_FRAC, right=RIGHT_FRAC, top=0.84, bottom=0.11, hspace=0.36,
    )
    mark_times = {}
    for co in callouts:
        mark_times.setdefault(co.signal, []).append((co.t_us, co.color))

    for axis, name in zip(axes, names):
        axis.set_xlim(start_us, end_us + pad_right)
        axis.set_ylim(-0.22, 1.78)
        axis.set_yticks([])
        axis.set_ylabel(name, rotation=0, ha="right", va="center", fontsize=8, labelpad=6)
        pts = waves.get(name) or [(start_ps, "x")]
        segs = merge_segments(pts, end_ps)
        _draw_lane(axis, name, segs, span, fig, mark_times.get(name, []))
        if is_bit(name):
            prev = None
            for t0, t1, val in segs:
                if str(val).lower() not in ("0", "1"):
                    prev = None
                    continue
                y = int(val)
                if prev is not None and prev != y:
                    x = t0 / 1e6
                    axis.plot([x, x], [prev, y], color=DIGITAL, lw=1.15)
                prev = y
        axis.spines["top"].set_visible(False)
        axis.spines["right"].set_visible(False)
        axis.tick_params(labelsize=7.5)
        for spine in axis.spines.values():
            spine.set_clip_on(False)

    by_name = {name: axis for name, axis in zip(names, axes)}
    for co in callouts:
        axis = by_name.get(co.signal)
        if axis is None:
            continue
        add_callout(
            axis, co.t_us, co.text, color=co.color, ha=co.ha, dx=co.dx,
            point_y=co.point_y, text_y=co.text_y,
        )

    axes[-1].set_xlabel(xlabel, fontsize=9)
    axes[0].set_title(escape_title(title), fontsize=11)
    fig.savefig(png, dpi=200)
    plt.close(fig)
    print("wrote", png, "end_us", round(end_us, 4))


if __name__ == "__main__":
    start = float(sys.argv[4]) if len(sys.argv) > 4 else None
    end = float(sys.argv[5]) if len(sys.argv) > 5 else None
    draw(sys.argv[1], sys.argv[2], sys.argv[3], start, end)
