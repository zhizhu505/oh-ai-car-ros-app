from pathlib import Path
import re

root = Path("finialppt")
s = (root / "index.html").read_text(encoding="utf-8")
missing = []
for src in re.findall(r'<img[^>]+src="([^"]+)"', s):
    if not (root / src).exists():
        missing.append(src)
print("chars", len(s))
print("sections", s.count("<section"))
print("答辩 count", s.count("答辩"))
print("最终答辩 count", s.count("最终答辩"))
print("missing", missing)
