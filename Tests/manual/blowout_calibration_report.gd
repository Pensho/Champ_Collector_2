extends GutTest

## Not part of the default suite (Tests/unit/ only) — run explicitly:
##   Tests/run_tests.sh -gtest=res://Tests/manual/blowout_calibration_report.gd -gexit
##
## Runs Scripts/Debug/blowout_calibration.gd's six reports through the same GUT entry path
## as the other Tests/manual/ scripts, rather than the bare `-s` SceneTree entry point the
## file's own header still documents. Skills.MitigatedDamage (which the reports call by way
## of BlowoutCalibration._Damage) transitively pulls in Character through Skills's other
## static helpers, and a bare `-s` script's static dependency graph cannot reach Character.new()
## before its own compile step runs (see team_corpus_sweep.gd's header for the full
## explanation) — so this file exists once the swap to Skills.MitigatedDamageUnrounded made
## that graph reachable from blowout_calibration.gd. The six _Report* methods are static on
## BlowoutCalibration for exactly this reason: this file calls them directly rather than
## instantiating a SceneTree.

func test_prints_all_six_calibration_reports() -> void:
	gut.p("=== Blowout calibration ===")
	gut.p("Caster scaled aggregate (basic skill, no modifiers): %.0f" % BlowoutCalibration.CASTER_SCALED_BASE)
	gut.p("Minimum damage percent: %.2f" % GameBalance.MINIMUM_DMG_PERCENT)

	BlowoutCalibration._ReportBaselines()
	BlowoutCalibration._ReportPlacementComparison()
	BlowoutCalibration._ReportFactorRequirements()
	BlowoutCalibration._ReportDefenceIgnoreSweep()
	BlowoutCalibration._ReportHealthImplications()
	BlowoutCalibration._ReportGearCeiling()

	# No hand-carried figure to assert against — this script's whole point is printed stdout,
	# diffed against a prior baseline by hand when the formula or presets change.
	# One assertion so GUT does not flag a print-only test as risky/pending.
	assert_true(true, "Six calibration reports printed above")
