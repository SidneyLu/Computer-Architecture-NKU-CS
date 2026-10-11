# -*- coding: utf-8 -*-
import sys


def load_window(path, names, t0_ns, t1_ns):
    t0, t1 = int(t0_ns * 1000), int(t1_ns * 1000)
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
    return waves


def hex_of(bits):
    if any(ch in "xz" for ch in bits.lower()):
        return "X"
    return format(int(bits, 2), "x")


names = [
    "ds_ready_go",
    "ds_pc",
    "rs_value",
    "es_dest",
    "debug_wb_pc",
    "debug_wb_rf_wnum",
    "debug_wb_rf_wdata",
    "debug_wb_err",
]
path = sys.argv[1]
t0, t1 = float(sys.argv[2]), float(sys.argv[3])
waves = load_window(path, names, t0, t1)
bit = {"ds_ready_go", "debug_wb_err"}
for n in names:
    print("===", n, "===")
    pts = waves[n]
    for i, (t, v) in enumerate(pts):
        t2 = pts[i + 1][0] if i + 1 < len(pts) else int(t1 * 1000)
        shown = v if n in bit else hex_of(v)
        print(f"  {t/1000:.0f}-{t2/1000:.0f} ns  {shown}")
