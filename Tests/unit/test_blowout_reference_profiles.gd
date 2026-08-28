extends GutTest

# Coverage for Scripts/Debug/blowout_calibration.gd's REFERENCE_PROFILES (Concept_Document.md
# 1.1.2): the Boss profile is the one Scripts/Debug/burst_reachability.gd scores every
# candidate against, so a stray edit to it silently invalidates every recorded sweep figure
# (Role_Kit_Design.md section 4). Health is deliberately not asserted — it is the deferred
# quantity, unset until progression and gear tiers exist.

func test_boss_reference_profile_carries_the_scorers_defence_and_knowledge() -> void:
	var boss_profile: Array = BlowoutCalibration.REFERENCE_PROFILES[0]
	assert_eq(String(boss_profile[0]), "Boss", "Index 0 must be the Boss-tier profile")
	assert_almost_eq(float(boss_profile[2]), 120.0, 0.0001,
			"Boss Defence must stay 120, or every recorded burst_reachability.gd figure moves")
	assert_almost_eq(float(boss_profile[3]), 80.0, 0.0001,
			"Boss Knowledge must stay 80, or every recorded burst_reachability.gd figure moves")
