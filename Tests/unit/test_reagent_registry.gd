extends GutTest

# Data-integrity net for the reagent catalog (Plan_Reagent_Data_And_Catalog): every
# registered ReagentData loads correctly and is internally consistent, mirroring
# test_status_effect_registry.gd's per-entry checks.

const VALID_TARGET_KINDS_BY_EFFECT: Dictionary[ReagentData.EffectKind, Array] = {
	ReagentData.EffectKind.Attribute_Increase: [ReagentData.TargetKind.Self_Target],
	ReagentData.EffectKind.Heal: [ReagentData.TargetKind.One_Ally],
	ReagentData.EffectKind.Remove_Debuffs: [ReagentData.TargetKind.One_Ally],
	ReagentData.EffectKind.Destroy_Enemy_Buffs: [ReagentData.TargetKind.One_Enemy],
	ReagentData.EffectKind.Reduce_Cooldown: [ReagentData.TargetKind.One_Ally],
	ReagentData.EffectKind.Turn_Bar_Reset: [ReagentData.TargetKind.Self_Target],
	ReagentData.EffectKind.Clear_Zone: [ReagentData.TargetKind.Zone_Section],
	ReagentData.EffectKind.Random_Attribute_Increase: [ReagentData.TargetKind.Self_Target],
	ReagentData.EffectKind.Health_Cost_Damage_Bonus: [ReagentData.TargetKind.Self_Target],
}

func test_every_registered_reagent_loads() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		assert_not_null(ReagentRegistry.Get(reagent_id),
			"Reagent id %s has no ReagentData registered" % reagent_id)

func test_registry_keys_are_unique() -> void:
	var seen_ids: Dictionary[String, bool] = {}
	for reagent_id in ReagentRegistry.REAGENTS:
		assert_false(seen_ids.has(reagent_id), "Duplicate reagent id: %s" % reagent_id)
		seen_ids[reagent_id] = true

func test_every_reagent_rarity_is_uncommon_through_legendary() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		var data: ReagentData = ReagentRegistry.Get(reagent_id)
		assert_true(data.rarity >= Types.Rarity.Uncommon and data.rarity <= Types.Rarity.Legendary,
			"%s has rarity %s outside Uncommon..Legendary" % [reagent_id, data.rarity])

func test_binary_reagents_have_no_scalar_magnitude() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		var data: ReagentData = ReagentRegistry.Get(reagent_id)
		if(data.binary):
			assert_eq(data.magnitude, 0.0, "%s is binary but has a scalar magnitude" % reagent_id)

func test_scalar_reagents_have_a_positive_magnitude() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		var data: ReagentData = ReagentRegistry.Get(reagent_id)
		if(not data.binary):
			assert_gt(data.magnitude, 0.0, "%s is scalar but has no positive magnitude" % reagent_id)

func test_target_kind_is_valid_for_effect_kind() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		var data: ReagentData = ReagentRegistry.Get(reagent_id)
		var valid_targets: Array = VALID_TARGET_KINDS_BY_EFFECT[data.effect_kind]
		assert_true(valid_targets.has(data.target_kind),
			"%s has target_kind %s invalid for effect_kind %s" %
			[reagent_id, data.target_kind, data.effect_kind])

func test_names_and_descriptions_are_non_empty() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		var data: ReagentData = ReagentRegistry.Get(reagent_id)
		assert_false(data.display_name.is_empty(), "%s has an empty display_name" % reagent_id)
		assert_false(data.description.is_empty(), "%s has an empty description" % reagent_id)

func test_icon_is_non_null() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		var data: ReagentData = ReagentRegistry.Get(reagent_id)
		assert_not_null(data.icon, "%s has no icon" % reagent_id)

func test_binary_reagent_descriptions_mention_potency_modifiers() -> void:
	for reagent_id in ReagentRegistry.REAGENTS:
		var data: ReagentData = ReagentRegistry.Get(reagent_id)
		if(data.binary):
			assert_true(data.description.contains("potency modifier"),
				"%s is binary but its description doesn't state potency-modifier immunity" % reagent_id)
