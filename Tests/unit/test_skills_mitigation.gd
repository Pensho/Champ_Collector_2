extends GutTest

# Coverage for Skills.MitigatedDamageUnrounded's Defence formula (Concept_Document.md 1.1.4):
# Defence's mitigation ratio is taken against GameBalance.DEFENCE_SCALE_CONSTANT, not the
# caster's own scaled aggregate, so it keeps its full percentage weight at burst scale.

func test_two_defence_values_differentiate_damage_the_same_at_basic_and_burst_scale() -> void:
	var low_defence: float = 75.0
	var high_defence: float = 280.0
	var basic_aggregate: float = 100.0
	var burst_aggregate: float = 100.0 * 33.0

	var basic_ratio: float = (
			Skills.MitigatedDamageUnrounded(low_defence, basic_aggregate, 1.0, 1.0)
			/ Skills.MitigatedDamageUnrounded(high_defence, basic_aggregate, 1.0, 1.0))
	var burst_ratio: float = (
			Skills.MitigatedDamageUnrounded(low_defence, burst_aggregate, 1.0, 1.0)
			/ Skills.MitigatedDamageUnrounded(high_defence, burst_aggregate, 1.0, 1.0))

	assert_almost_eq(burst_ratio, basic_ratio, 0.01,
		"Defence must differentiate damage by the same ratio at burst scale as at basic-hit scale")

func test_defence_ignore_factor_still_moves_burst_damage_significantly() -> void:
	var burst_aggregate: float = 100.0 * 33.0
	var full_defence_damage: float = Skills.MitigatedDamageUnrounded(120.0, burst_aggregate, 1.0, 1.0)
	var ignored_defence_damage: float = Skills.MitigatedDamageUnrounded(0.0, burst_aggregate, 1.0, 1.0)

	assert_gt(ignored_defence_damage, full_defence_damage * 1.5,
		"Defense_Ignore_Factor must still meaningfully move damage at burst scale")

func test_mitigated_damage_pinned_regression() -> void:
	assert_almost_eq(
			Skills.MitigatedDamageUnrounded(120.0, 100.0, 1.0, 1.0), 50.9, 0.1,
			"Pinned basic-hit damage against Troll's Defence")
	assert_almost_eq(
			Skills.MitigatedDamageUnrounded(120.0, 3300.0, 1.0, 1.0), 1680.0, 1.0,
			"Pinned burst damage against Troll's Defence")
