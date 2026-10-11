# -*- coding: utf-8 -*-
path = r"d:\Architecture\lab1\report\fig\fwd.vcd"
want = {
    "ds_pc", "ds_ready_go", "ds_inst", "rs_value", "rt_value",
    "es_alu_result", "es_dest", "es_load_op", "es_valid", "es_pc",
    "ms_final_result", "ms_dest", "ms_valid", "ms_pc",
    "rf_wdata", "rf_waddr",
}
ids = {}
last = {n: "x" for n in want}
t = 0
prev_t = None
in_def = True

def hx(bits):
    if not bits or any(ch in "xz" for ch in bits.lower()):
        return "X"
    return format(int(bits, 2), "x")

windows = [(2480, 2620), (14360, 14440), (14730, 14820)]

def emit(tt):
    ns = tt / 1000.0
    if int(tt) % 10000 != 5000:
        return
    if not any(a <= ns <= b for a, b in windows):
        return
    print(
        f"{ns:8.0f} go={last['ds_ready_go']} "
        f"dspc={hx(last['ds_pc']):8s} inst={hx(last['ds_inst']):8s} "
        f"rs={hx(last['rs_value']):8s} rt={hx(last['rt_value']):8s} "
        f"espc={hx(last['es_pc']):8s} esalu={hx(last['es_alu_result']):8s} "
        f"ed={hx(last['es_dest']):2s} ld={last['es_load_op']} ev={last['es_valid']} "
        f"mspc={hx(last['ms_pc']):8s} msf={hx(last['ms_final_result']):8s} "
        f"md={hx(last['ms_dest']):2s} mv={last['ms_valid']} "
        f"rfw={hx(last['rf_wdata']):8s} rfa={hx(last['rf_waddr']):2s}"
    )

print("time_ns ...")
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
            if prev_t is not None:
                emit(prev_t)
            t = int(line[1:])
            prev_t = t
            if t / 1000.0 > 15000:
                emit(t)
                break
        else:
            if line[0] == "b":
                bits, ident = line[1:].split()
                name = ids.get(ident)
                if name:
                    last[name] = bits
            elif line[0] in "01xz":
                name = ids.get(line[1:])
                if name:
                    last[name] = line[0]
