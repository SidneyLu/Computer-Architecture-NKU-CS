import sys
from pathlib import Path

p = Path(r"D:\Architecture\lab4\CPU_CDE_SRAM\mycpu_sram_verify\rtl\CONFREG\confreg.v")
hexv = sys.argv[1]
with p.open("r", encoding="utf-8", newline="") as f:
    text = f.read()
old = "`define RANDOM_SEED {7'b1010101,16'h"
i = text.find(old)
if i < 0:
    raise SystemExit("RANDOM_SEED not found")
j = text.find("}", i)
text = text[:i] + old + hexv + text[j:]
with p.open("w", encoding="utf-8", newline="") as f:
    f.write(text)
print("RANDOM_SEED", hexv)
