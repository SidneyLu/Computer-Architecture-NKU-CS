import sys
from pathlib import Path

p = Path(sys.argv[1])
hexv = sys.argv[2]
with p.open("r", encoding="utf-8", newline="") as f:
    text = f.read()
old = "`define RANDOM_SEED {7'b1010101,16'h"
i = text.find(old)
if i < 0:
    raise SystemExit(f"RANDOM_SEED not found in {p}")
j = text.find("}", i)
text = text[:i] + old + hexv + text[j:]
with p.open("w", encoding="utf-8", newline="") as f:
    f.write(text)
print(p.name, "RANDOM_SEED", hexv)
