#!/usr/bin/env bash
# Screenshot aus dem Spiel ohne Bildschirm (Xvfb). Argumente wie in screenshot.gd.
#   bash tools/qa/shot.sh out=/tmp/bild.png level=res://scenes/world/village.tscn
set -e
cd "$(dirname "$0")/../.."
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --audio-driver Dummy \
	--script res://tools/qa/screenshot.gd -- "$@" 2>&1 | grep -E "Screenshot|SCRIPT ERROR|ERROR: [^4]" || true
