# -*- coding: utf-8 -*-
import sys
sys.path.insert(0, r"d:\Architecture\lab1\report\fig")
from plot_vcd import hex_of, load_window

VCD = r"d:\Architecture\lab2\report\fig\cases.vcd"
NAMES = [
    "ds_pc", "ds_ready_go", "rs_value", "rt_value", "br_taken",
    "es_pc", "es_ready_go", "hi", "lo",
    "data_sram_wen", "data_sram_addr", "data_sram_wdata",
    "ms_pc", "mem_word", "ms_rt_value", "ms_final_result",
    "debug_wb_pc", "debug_wb_rf_wen", "debug_wb_rf_wnum", "debug_wb_rf_wdata",
]
BIT = {"ds_ready_go", "br_taken", "es_ready_go"}
windows = [
    ("sltiu", 675600, 676200),
    ("andi", 697030, 697600),
    ("mult", 993630, 994300),
    ("bgez", 1102990, 1103600),
    ("bltzal", 1246620, 1247300),
    ("lwr", 1545300, 1545900),
    ("sb", 1558390, 1559000),
]

def show(bits):
    if any(c in "xz" for c in bits.lower()):
        return "X"
    return bits if len(bits) <= 4 else hex_of(bits)

for name, t0, t1 in windows:
    print("====", name, t0, t1)
    waves = load_window(VCD, NAMES, t0, t1)
    for sig in NAMES:
        pts = waves[sig]
        prev = None
        bits = []
        for t, v in pts:
            if v == prev:
                continue
            prev = v
            bits.append(f"{t/1000:.0f}:{show(v)}")
        print(f"  {sig}: {', '.join(bits)}")
