# -*- coding: utf-8 -*-
import os
os.environ.setdefault("MPLBACKEND", "Agg")

path = r"d:\Architecture\lab1\report\fig\fwd.vcd"
want = {
    "ds_pc", "ds_ready_go", "ds_inst", "rs_value", "rt_value",
    "es_alu_result", "es_dest", "es_load_op", "es_valid", "es_pc",
    "ms_final_result", "ms_dest", "ms_valid", "ms_pc",
    "rf_wdata", "rf_waddr",
}
ids = {}
last = {}
t = 0
hits_408b0 = []
hits_408c8 = []
hits_00694 = []
hits_00698 = []
hits_de24 = []
stalls = []
in_def = True

def as_int(bits):
    if not bits or any(ch in "xz" for ch in bits.lower()):
        return None
    return int(bits, 2)

with open(path, encoding="utf-8", errors="replace") as handle:
    for raw in handle:
        line = raw.strip()
        if not line:
            continue
        if line.startswith("$var"):
            parts = line.split()
            if parts[4] in want:
                ids[parts[3]] = parts[4]
        elif line.startswith("$enddefinitions"):
            in_def = False
        elif in_def or line.startswith("$"):
            continue
        elif line.startswith("#"):
            t = int(line[1:])
            if t > 30_000_000_000:  # 30 us in ps? VCD from xsim is often ps. 30us = 30e9 ps
                # xsim Time Resolution is 1ps. #2500000 would be 2.5us if ns... 
                # previous plot used t0_ns * 1000, so VCD time unit is ps (ns*1000).
                pass
            if t > 20_000_000_000:
                break
        else:
            name = None
            val = None
            if line[0] == "b":
                bits, ident = line[1:].split()
                name = ids.get(ident)
                val = bits
            elif line[0] in "01xz":
                name = ids.get(line[1:])
                val = line[0]
            if name:
                last[name] = val
                pc = as_int(last.get("ds_pc", "x"))
                if pc is None:
                    continue
                ns = t / 1000.0
                if pc == 0xbfc408b0:
                    hits_408b0.append((ns, last.get("ds_ready_go"), last.get("rs_value"), last.get("es_alu_result"), last.get("es_dest"), last.get("es_load_op")))
                if pc == 0xbfc408c8:
                    hits_408c8.append((ns, last.get("ds_ready_go"), last.get("rs_value"), last.get("es_alu_result"), last.get("ms_final_result"), last.get("es_dest"), last.get("ms_dest")))
                if pc == 0xbfc00694:
                    hits_00694.append((ns, last.get("ds_ready_go"), last.get("es_load_op"), last.get("es_pc")))
                if pc == 0xbfc00698:
                    hits_00698.append((ns, last.get("ds_ready_go"), last.get("rs_value"), last.get("es_alu_result"), last.get("ms_final_result"), last.get("es_load_op"), last.get("es_dest"), last.get("ms_dest")))
                if pc == 0xbfc6de24:
                    hits_de24.append((ns, last.get("ds_ready_go"), last.get("rs_value"), last.get("es_alu_result")))
                if last.get("ds_ready_go") == "0" and ns < 20000:
                    stalls.append((ns, hex(pc), last.get("es_load_op"), last.get("es_dest"), last.get("rs_value")))

print("ids", ids)
print("n408b0", len(hits_408b0), "first", hits_408b0[:8])
print("n408c8", len(hits_408c8), "first", hits_408c8[:8])
print("n00694", len(hits_00694), "first", hits_00694[:6])
print("n00698", len(hits_00698), "first", hits_00698[:10])
print("n6de24", len(hits_de24), "first", hits_de24[:6])
print("stalls<20us", len(stalls))
for row in stalls[:20]:
    print(" stall", row)
