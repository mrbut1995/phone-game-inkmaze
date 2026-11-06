#!/usr/bin/env python3
"""Generate placeholder audio (WAV) + manifest so scenes/exports can reference sounds before real audio exists.

  python tools/placeholder_audio.py sfx/hit --kind beep --seconds 0.15 --freq 660 --used-by "data/items/..."
  python tools/placeholder_audio.py sfx/explosion --kind noise --seconds 0.4
  python tools/placeholder_audio.py sfx/pickup --kind sweep --seconds 0.25
  python tools/placeholder_audio.py music/overworld --kind loop --seconds 8
  python tools/placeholder_audio.py sfx/silence --kind silence --seconds 0.1
Output: assets/audio-placeholder/<category>/<name>.wav (16-bit mono 22.05 kHz) and a row in assets/audio-placeholder/MANIFEST.md.
"""
from __future__ import annotations

import argparse
import math
import random
import re
import struct
import sys
import wave

from _common import ROOT, setup_stdout

RATE = 22050
NOTES = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63]  # simple C-major arpeggio for loops


def samples(kind: str, seconds: float, freq: float):
    n = int(RATE * seconds)
    rng = random.Random(1)
    for i in range(n):
        t = i / RATE
        env = min(1.0, (n - i) / (RATE * 0.02), i / (RATE * 0.005 + 1))  # tiny fade in/out, avoids clicks
        if kind == "silence":
            v = 0.0
        elif kind == "noise":
            v = rng.uniform(-1, 1) * (1 - i / n)
        elif kind == "sweep":
            f = freq * (1 + 2 * i / n)
            v = math.sin(2 * math.pi * f * t)
        elif kind == "loop":
            step = int(t / 0.5) % len(NOTES)
            v = 0.6 * math.sin(2 * math.pi * NOTES[step] * t) * (1 - ((t % 0.5) / 0.5) * 0.6)
        else:
            v = math.sin(2 * math.pi * freq * t)
        yield int(max(-1.0, min(1.0, v * env * 0.5)) * 32767)


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("name", help="<category>/<snake_case_name>")
    ap.add_argument("--kind", choices=["beep", "noise", "sweep", "loop", "silence"], default="beep")
    ap.add_argument("--seconds", type=float, default=0.2)
    ap.add_argument("--freq", type=float, default=440.0)
    ap.add_argument("--used-by", default="TBD")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    rel = a.name.replace("\\", "/").strip("/")
    if not re.match(r"^[a-z0-9_]+(/[a-z0-9_]+)+$", rel):
        print("ERROR: name must be <category>/<snake_case_name>")
        return 1
    out = ROOT / "assets" / "audio-placeholder" / f"{rel}.wav"
    if out.exists() and not a.force:
        print(f"ERROR: {rel}.wav exists (use --force)")
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(out), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", s) for s in samples(a.kind, a.seconds, a.freq)))
    manifest = out.parent.parent / "MANIFEST.md"
    if not manifest.exists():
        manifest.write_text("# Audio placeholder manifest\n\n| File | Used by | Kind | Seconds | Status | Final path |\n|---|---|---|---|---|---|\n", encoding="utf-8")
    with manifest.open("a", encoding="utf-8", newline="\n") as f:
        f.write(f"| {rel}.wav | {a.used_by} | {a.kind} | {a.seconds:g} | placeholder | - |\n")
    print(f"created assets/audio-placeholder/{rel}.wav ({a.kind}, {a.seconds:g}s); manifest updated. Loop music: set loop in the import settings.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
