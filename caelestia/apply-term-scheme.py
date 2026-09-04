#!/usr/bin/env python3
"""Apply caelestia scheme colours to terminals, replacing the CLI's apply_terms
(disabled via theme.enableTerm in cli.json).

Policy:
  - Always regenerate ~/.local/state/caelestia/sequences.txt for new shells
    (fish only sources it in dark mode, and strips OSC 11 inside tmux).
  - Light mode: never touch running terminals — foot instances keep their dark palette.
  - Dark mode: send sequences to all ptys, but strip OSC 11 (background) for tmux
    pane ttys, since tmux turns it into an opaque pane background.
"""

import json
import os
import re
import subprocess
from pathlib import Path

state_dir = Path.home() / ".local/state/caelestia"

OSC11_RE = re.compile(r"\x1b\]11;[^\x1b]*\x1b\\")


def seq(c: str, *i: int) -> str:
    return f"\x1b]{';'.join(map(str, i))};rgb:{c[0:2]}/{c[2:4]}/{c[4:6]}\x1b\\"


def gen_sequences(colours: dict[str, str]) -> str:
    s = (
        seq(colours["onSurface"], 10)
        + seq(colours["surface"], 11)
        + seq(colours["secondary"], 12)
        + seq(colours["secondary"], 17)
    )
    for n in range(16):
        s += seq(colours[f"term{n}"], 4, n)
    s += seq(colours["primary"], 4, 16)
    s += seq(colours["secondary"], 4, 17)
    s += seq(colours["tertiary"], 4, 18)
    return s


def tmux_pane_ttys() -> set[str]:
    try:
        out = subprocess.run(
            ["tmux", "list-panes", "-a", "-F", "#{pane_tty}"],
            capture_output=True, text=True, timeout=5,
        ).stdout
        return {line.strip() for line in out.splitlines() if line.strip()}
    except (OSError, subprocess.TimeoutExpired):
        return set()


def write_pty(pt: Path, data: str) -> None:
    try:
        fd = os.open(str(pt), os.O_WRONLY | os.O_NONBLOCK | os.O_NOCTTY)
        try:
            os.write(fd, data.encode())
        finally:
            os.close(fd)
    except OSError:
        pass


def main() -> None:
    scheme = json.loads((state_dir / "scheme.json").read_text())
    sequences = gen_sequences(scheme["colours"])

    state_dir.mkdir(parents=True, exist_ok=True)
    (state_dir / "sequences.txt").write_text(sequences)

    if scheme.get("mode") != "dark":
        return

    # OSC 111 resets the background, clearing any opaque pane background tmux
    # stored from a previous OSC 11
    no_bg = OSC11_RE.sub("", sequences) + "\x1b]111\x1b\\"
    panes = tmux_pane_ttys()
    for pt in Path("/dev/pts").iterdir():
        if pt.name.isdigit():
            write_pty(pt, no_bg if str(pt) in panes else sequences)


if __name__ == "__main__":
    main()
