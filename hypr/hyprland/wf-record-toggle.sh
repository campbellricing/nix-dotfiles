#!/usr/bin/env bash
# Toggle screen recording via wf-recorder. Used in place of caelestia's
# built-in record command, which hardcodes gpu-screen-recorder and can't
# run on this machine's nouveau driver (no NVENC / unrecognised GL vendor).
set -euo pipefail

rec_dir="$HOME/Videos/Recordings"

if pgrep -x wf-recorder >/dev/null; then
	pkill -INT -x wf-recorder
	while pgrep -x wf-recorder >/dev/null; do sleep 0.1; done
	notify-send "Recording stopped" "Saved in $rec_dir"
else
	mkdir -p "$rec_dir"
	out="$rec_dir/recording_$(date +%Y%m%d_%H-%M-%S).mp4"
	setsid wf-recorder -f "$out" >/tmp/wf-recorder.log 2>&1 &
	disown
	notify-send "Recording started" "$out"
fi
