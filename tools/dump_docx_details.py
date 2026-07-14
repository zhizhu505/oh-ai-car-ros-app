from __future__ import annotations

import sys
import zipfile
from pathlib import Path

from docx import Document
from PIL import Image


def main() -> int:
    path = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    doc = Document(path)

    print("PARAGRAPHS")
    for i, p in enumerate(doc.paragraphs):
        text = p.text.strip().replace("\n", " ")
        style = p.style.name if p.style is not None else ""
        print(f"{i:04d} [{style}] {text}")

    print("\nINLINE SHAPES")
    for i, shape in enumerate(doc.inline_shapes, 1):
        print(f"{i:02d} width={shape.width} height={shape.height}")

    print("\nMEDIA")
    with zipfile.ZipFile(path) as zf:
        for name in sorted(n for n in zf.namelist() if n.startswith("word/media/") and not n.endswith("/")):
            target = out_dir / Path(name).name
            target.write_bytes(zf.read(name))
            try:
                with Image.open(target) as img:
                    print(f"{Path(name).name}: {img.width}x{img.height} {img.mode}")
            except Exception as exc:
                print(f"{Path(name).name}: unreadable {exc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
