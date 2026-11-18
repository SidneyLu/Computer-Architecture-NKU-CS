# Draw the lab4 handshake windows from the short func_lab9 dumps.
import csv
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimHei", "DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False

SIM = r"D:\Architecture\lab4\sim"
OUT = r"D:\Architecture\lab4\report\fig"
os.makedirs(OUT, exist_ok=True)

IF_TICKS = [(0, "IDLE"), (1, "REQ"), (2, "WAIT"), (3, "HAVE")]
EX_TICKS = [(0, "IDLE"), (1, "REQ"), (2, "WAIT"), (3, "DONE")]
RD_TICKS = [(0, "IDLE"), (1, "AR"), (2, "R")]
WR_TICKS = [(0, "IDLE"), (3, "WRITE"), (4, "WRESP")]


def load(name):
    with open(os.path.join(SIM, name), newline="") as f:
        rows = list(csv.DictReader(f))
    return {int(r["cyc"]): r for r in rows}


def bit(text):
    text = (text or "").strip().lower()
    if not text or "x" in text or "z" in text:
        return 0
    return int(text, 2)


def hx(text):
    text = (text or "").strip().lower()
    if not text or "x" in text or "z" in text:
        return 0
    return int(text, 16)


def mask_bit(text, index):
    text = (text or "").strip()
    if not text or "x" in text:
        return 0
    # CSV stores mask as a 5-bit binary string, bit 4 on the left.
    return int(text[-1 - index])


def save(rows_by_cyc, lo, hi, name, title, note, series):
    cyc = list(range(lo, hi + 1))
    x = cyc + [hi + 1]
    fig, axes = plt.subplots(len(series), 1, sharex=True,
                             figsize=(8.4, 0.72 * len(series) + 0.85))
    for ax, (lab, fn, ticks) in zip(axes, series):
        ys = [fn(rows_by_cyc[c]) for c in cyc] + [fn(rows_by_cyc[hi])]
        ax.step(x, ys, where="post", color="#1f4e79", linewidth=1.15)
        ax.set_ylabel(lab, fontsize=8)
        ax.grid(True, axis="x", linewidth=0.35, color="#d5d5d5")
        ax.tick_params(labelsize=7)
        ax.set_xlim(lo, hi + 1)
        if ticks == "bit":
            ax.set_ylim(-0.2, 1.35)
            ax.set_yticks([0, 1])
        else:
            top = max(t[0] for t in ticks)
            ax.set_ylim(-0.45, top + 0.55)
            ax.set_yticks([t[0] for t in ticks])
            ax.set_yticklabels([t[1] for t in ticks], fontsize=7)
    axes[-1].set_xlabel("复位后的拍号")
    fig.suptitle(title, fontsize=12)
    fig.text(0.01, 0.004, note, fontsize=7.5)
    fig.tight_layout(rect=(0, 0.03, 1, 0.96))
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=140)
    plt.close(fig)
    print("wrote", path)


def main():
    sram = load("sram_wave.csv")
    save(sram, 3, 16, "sram_fetch.png",
         "类 SRAM 取指：第一条指令被短延迟掩码挡住",
         "地址 0xbfc00000    读回 0x2408ffff（li t0, -1）    取指口使用 mask[1:0]",
         [("取指状态", lambda r: int(r["fst"]), IF_TICKS),
          ("inst req", lambda r: bit(r["ireq"]), "bit"),
          ("addr_ok", lambda r: bit(r["iok"]), "bit"),
          ("data_ok", lambda r: bit(r["idok"]), "bit"),
          ("mask[1]", lambda r: mask_bit(r["mask"], 1), "bit"),
          ("mask[0]", lambda r: mask_bit(r["mask"], 0), "bit")])

    save(sram, 22, 36, "sram_delay.png",
         "延迟槽：b locate 等到 0xbfc0000c 再取目标",
         "0xbfc00008 = b 0xbfc006b8    延迟槽 0xbfc0000c = nop    下一请求 0xbfc006b8",
         [("取指状态", lambda r: int(r["fst"]), IF_TICKS),
          ("wait_bd", lambda r: bit(r["wait_bd"]), "bit"),
          ("br_taken", lambda r: bit(r["br"]), "bit"),
          ("inst req", lambda r: bit(r["ireq"]), "bit"),
          ("addr_ok", lambda r: bit(r["iok"]), "bit")])

    save(sram, 141, 150, "sram_store.png",
         "第一条 sw：写 LED_RG1（confreg）",
         "sw t1, 0(a0)    地址 0xbfaff008    数据 0x2    wstrb = 0xf",
         [("访存状态", lambda r: int(r["dst"]), EX_TICKS),
          ("data req", lambda r: bit(r["dreq"]), "bit"),
          ("wr", lambda r: bit(r["dwr"]), "bit"),
          ("addr_ok", lambda r: bit(r["dok_a"]), "bit"),
          ("data_ok", lambda r: bit(r["dok_d"]), "bit")])

    axi = load("axi_wave.csv")
    save(axi, 4, 14, "axi_read.png",
         "AXI3 取指读：AR 握手之后等 R",
         "地址 0xbfc00000    读回 0x2408ffff    arid = 0    arlen = 0",
         [("转换器", lambda r: int(r["ist"]), RD_TICKS),
          ("arvalid", lambda r: bit(r["iarv"]), "bit"),
          ("arready", lambda r: bit(r["iarr"]), "bit"),
          ("rvalid", lambda r: bit(r["irv"]), "bit"),
          ("rready", lambda r: bit(r["irr"]), "bit"),
          ("rlast", lambda r: bit(r["irlast"]), "bit"),
          ("data_ok", lambda r: bit(r["idok"]), "bit")])

    save(axi, 188, 200, "axi_write.png",
         "AXI3 写：AW 与 W 分拍握手，再等 B",
         "地址 0xbfaff008    数据 0x2    wstrb = 0xf    awid = 8",
         [("转换器", lambda r: int(r["daxist"]), WR_TICKS),
          ("awvalid", lambda r: bit(r["dawv"]), "bit"),
          ("awready", lambda r: bit(r["dawr"]), "bit"),
          ("wvalid", lambda r: bit(r["dwv"]), "bit"),
          ("wready", lambda r: bit(r["dww"]), "bit"),
          ("bvalid", lambda r: bit(r["dbv"]), "bit"),
          ("bready", lambda r: bit(r["dbr"]), "bit")])

    save(axi, 213, 228, "axi_both.png",
         "主端口上读和写同时有效",
         "第 216 拍 arid = 0（取指 0xbfc00704），awid = 8（写 0xbfaff000）",
         [("取指转换器", lambda r: int(r["ist"]), RD_TICKS),
          ("数据转换器", lambda r: int(r["daxist"]), WR_TICKS),
          ("主端口 AR", lambda r: bit(r["arvalid"]), "bit"),
          ("主端口 AW", lambda r: bit(r["awvalid"]), "bit"),
          ("arid", lambda r: hx(r["arid"]), [(0, "0"), (8, "8")]),
          ("awid", lambda r: hx(r["awid"]), [(0, "0"), (8, "8")])])


if __name__ == "__main__":
    main()
