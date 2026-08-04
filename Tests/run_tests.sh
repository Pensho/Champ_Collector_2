#!/usr/bin/env bash
# Runs the GUT suite headlessly and prints only the run summary.
# GUT's per-test log is ~11k words on a green run; everything that matters
# (failing tests, their assert texts, totals) lives after "= Run Summary".
# Pass extra GUT arguments through, e.g. -gtest=res://Tests/unit/test_foo.gd
set -o pipefail

GODOT="/home/jonas/Documents/Godot_v4.7.1-stable_linux.x86_64"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT" || exit 1

if [ $# -gt 0 ]; then
	SELECTION=("$@")
else
	SELECTION=(-gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd)
fi

"$GODOT" --headless -s addons/gut/gut_cmdln.gd "${SELECTION[@]}" -gexit 2>&1 |
	sed -n '/= Run Summary/,$p' |
	grep -vE '^(WARNING|ERROR):|^   at: '
