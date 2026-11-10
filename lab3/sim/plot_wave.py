# Draw the lab3 waveform windows from wave.csv.
import csv
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

CSV = r"D:\Architecture\lab3\sim\wave.csv"
OUT = r"D:\Architecture\lab3\report\fig"
os.makedirs(OUT, exist_ok=True)

def hx(text):
    text = text.strip().lower()
    if not text or "x" in text or "z" in text:
        return 0
    return int(text, 16)


rows = []
with open(CSV, newline="") as f:
    for rec in csv.DictReader(f):
        rows.append({
            "cyc": int(rec["cyc"]),
            "wb_pc": hx(rec["wb_pc"]),
            "wb_valid": int(rec["wb_valid"]),
            "flush": int(rec["wb_flush"]),
            "cancel": int(rec["ex_cancel"]),
            "ds": int(rec["ds_valid"]),
            "wen": hx(rec["data_wen"]),
            "cause": hx(rec["cause"]),
            "epc": hx(rec["epc"]),
            "status": hx(rec["status"]),
            "int_req": int(rec["int_req"]),
            "ti": int(rec["ti"]),
            "hw": int(rec["hw_int"]),
        })


def excode(c):
    return (c >> 2) & 0x1F


def find(pred, start=0):
    for i in range(start, len(rows)):
        if pred(rows[i]):
            return i
    raise SystemExit("window not found")


labs = {}
with open(r"D:\Architecture\lab3\sim\wave_labels.vh") as f:
    for line in f:
        parts = line.split()
        if len(parts) == 3 and parts[0] == "`define":
            labs[parts[1]] = int(parts[2].replace("32'h", ""), 16)


def save(idx, name, title, extra):
    lo = max(0, idx - 6)
    hi = min(len(rows), idx + 18)
    sl = rows[lo:hi]
    x = [r["cyc"] for r in sl]
    fig, axes = plt.subplots(6, 1, sharex=True, figsize=(8.2, 6.4))
    series = [
        ([r["wb_pc"] & 0xFFF for r in sl], "WB PC[11:0]"),
        ([r["flush"] for r in sl], "wb_flush"),
        ([r["cancel"] for r in sl], "ex_cancel"),
        ([r["wen"] for r in sl], "data_wen"),
        ([excode(r["cause"]) for r in sl], "ExcCode"),
        ([r["epc"] & 0xFFF for r in sl], "EPC[11:0]"),
    ]
    for ax, (ys, lab) in zip(axes, series):
        ax.step(x, ys, where="post", color="#1f4e79", linewidth=1.2)
        ax.set_ylabel(lab, fontsize=8)
        ax.grid(True, axis="y", linewidth=0.3)
        ax.tick_params(labelsize=7)
    axes[-1].set_xlabel("cycle")
    fig.suptitle(title, fontsize=11)
    fig.text(0.01, 0.01, extra, fontsize=8, family="monospace")
    fig.tight_layout(rect=(0, 0.04, 1, 0.96))
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=140)
    plt.close(fig)
    print("wrote", path)


def save_int(idx, name, title, extra):
    lo = max(0, idx - 8)
    hi = min(len(rows), idx + 20)
    sl = rows[lo:hi]
    x = [r["cyc"] for r in sl]
    fig, axes = plt.subplots(6, 1, sharex=True, figsize=(8.2, 6.4))
    series = [
        ([r["wb_pc"] & 0xFFF for r in sl], "WB PC[11:0]"),
        ([r["int_req"] for r in sl], "int_req"),
        ([r["ti"] for r in sl], "TI"),
        ([(r["cause"] >> 8) & 1 for r in sl], "IP0"),
        ([(r["cause"] >> 10) & 1 for r in sl], "IP2"),
        ([r["hw"] for r in sl], "hw_int[0]"),
    ]
    for ax, (ys, lab) in zip(axes, series):
        ax.step(x, ys, where="post", color="#1f4e79", linewidth=1.2)
        ax.set_ylabel(lab, fontsize=8)
        ax.set_ylim(-0.1, max(1.2, max(ys) + 0.2))
        ax.grid(True, axis="y", linewidth=0.3)
        ax.tick_params(labelsize=7)
    axes[-1].set_xlabel("cycle")
    fig.suptitle(title, fontsize=11)
    fig.text(0.01, 0.01, extra, fontsize=8, family="monospace")
    fig.tight_layout(rect=(0, 0.04, 1, 0.96))
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=140)
    plt.close(fig)
    print("wrote", path)


# Cause is written with nonblocking assignment, so the flush cycle still
# shows the previous Cause. The following cycle has the new ExcCode and EPC.
def first_flush(pc):
    return find(lambda r: r["flush"] and r["wb_valid"] and r["wb_pc"] == pc)


sys_i = first_flush(labs["WAVE_DO_SYS"])
brk_i = first_flush(labs["WAVE_DO_BRK"])
ov_i = first_flush(labs["WAVE_DO_OV"] + 4)   # the add, not the lui
adel_i = first_flush(labs["WAVE_DO_ADEL"])
ri_i = first_flush(labs["WAVE_DO_RI"])

save(sys_i, "syscall.png", "SYSCALL",
     "EPC=0x%08x  ExcCode=8" % labs["WAVE_DO_SYS"])
save(brk_i, "break.png", "BREAK",
     "EPC=0x%08x  ExcCode=9" % labs["WAVE_DO_BRK"])
save(ov_i, "overflow.png", "Integer overflow",
     "EPC=0x%08x  ExcCode=12" % (labs["WAVE_DO_OV"] + 4))
save(adel_i, "adel.png", "Address error on load",
     "EPC=0x%08x  ExcCode=4" % labs["WAVE_DO_ADEL"])
save(ri_i, "ri.png", "Reserved instruction",
     "EPC=0x%08x  ExcCode=10" % labs["WAVE_DO_RI"])

soft_i = find(lambda r: r["flush"] and r["wb_valid"] and labs["WAVE_DO_RI"] < r["wb_pc"] < labs["WAVE_HANDLER"], ri_i + 1)
ti_i = find(lambda r: r["flush"] and r["wb_valid"] and (r["wb_pc"] == labs["WAVE_SPIN_TI"] or r["wb_pc"] == labs["WAVE_SPIN_TI"] + 4))
hw_i = find(lambda r: r["flush"] and r["wb_valid"] and (r["wb_pc"] == labs["WAVE_SPIN_HW"] or r["wb_pc"] == labs["WAVE_SPIN_HW"] + 4))

def note(i):
    # Cause/EPC update on the same edge as wb_flush, so the dump of that
    # edge still shows the previous value. The next cycle is the committed one.
    r = rows[min(i + 1, len(rows) - 1)]
    return "EPC=0x%08x  ExcCode=%d  BD=%d  victim PC=0x%08x" % (
        r["epc"], excode(r["cause"]), (r["cause"] >> 31) & 1, rows[i]["wb_pc"])

save_int(soft_i, "soft_int.png", "Software interrupt IP0", note(soft_i))
save_int(ti_i, "timer_int.png", "Timer interrupt IP7", note(ti_i))
save_int(hw_i, "hw_int.png", "Hardware interrupt hw_int[0] / IP2", note(hw_i))

print("SOFT", note(soft_i), "pc", hex(rows[soft_i]["wb_pc"]))
print("TI  ", note(ti_i), "pc", hex(rows[ti_i]["wb_pc"]))
print("HW  ", note(hw_i), "pc", hex(rows[hw_i]["wb_pc"]))
