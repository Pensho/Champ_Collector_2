#!/usr/bin/env bash
# Runs the GUT suite headlessly and prints only the run summary.
# GUT's per-test log is ~11k words on a green run; everything that matters
# (failing tests, their assert texts, totals) lives after "= Run Summary".
# Pass extra GUT arguments through, e.g. -gtest=res://Tests/unit/test_foo.gd
#
# Pass --mode <name> (e.g. --mode playtest) to also run the suite under that build
# mode's content pool, on top of the always-run full game. The mode is passed to
# Godot as an environment variable, not a command-line argument: GUT's own CLI parser
# hard-quits on any argument it does not recognize. See ContentPool.Active() and
# Documents/Test_Design_Document.md.
set -o pipefail

case "$(uname -s)" in
	MINGW*|MSYS*|CYGWIN*)
		GODOT="C:\\Users\\jpens\\Documents\\Godot_v4.7-stable_win64.exe"
		;;
	*)
		GODOT="/home/jonas/Documents/Godot_v4.7.1-stable_linux.x86_64"
		;;
esac
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT" || exit 1

MODE=""
ARGS=()
while [ $# -gt 0 ]; do
	case "$1" in
		--mode)
			if [ $# -lt 2 ]; then
				echo "--mode requires a mode name, e.g. --mode playtest" >&2
				exit 2
			fi
			MODE="$2"
			shift 2
			;;
		*)
			ARGS+=("$1")
			shift
			;;
	esac
done

if [ ${#ARGS[@]} -gt 0 ]; then
	SELECTION=("${ARGS[@]}")
else
	SELECTION=(-gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd)
fi

run_suite() {
	CHAMP_COLLECTOR_BUILD_MODE="$1" "$GODOT" --headless -s addons/gut/gut_cmdln.gd "${SELECTION[@]}" -gexit 2>&1 |
		sed -n '/= Run Summary/,$p' |
		grep -vE '^(WARNING|ERROR):|^   at: '
}

if [ -z "$MODE" ]; then
	run_suite ""
	exit $?
fi

echo "== Full game =="
run_suite ""
full_game_status=$?
echo
echo "== Build mode: $MODE =="
run_suite "$MODE"
mode_status=$?

if [ $full_game_status -ne 0 ] || [ $mode_status -ne 0 ]; then
	exit 1
fi
