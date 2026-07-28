extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _trait: CalibrationTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func before_each() -> void:
	_character = Character.new()
	_character._current_health = 10
	_trait = CalibrationTrait.new()
	_characters = {0: _character}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], []))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

# --- Rarity table ---

func test_per_charge_potency_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.04,
		Types.Rarity.Rare: 0.06,
		Types.Rarity.Epic: 0.08,
		Types.Rarity.Legendary: 0.10,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(CalibrationTrait.PER_CHARGE_POTENCY.get(rarity, 0.0), expected[rarity],
			"PER_CHARGE_POTENCY at %s" % Types.RarityName(rarity))

# --- Charge accumulation ---

func test_cornerstone_grants_one_charge() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	assert_eq(_trait._charges, 1)

func test_charges_capped_at_max() -> void:
	_InitTrait(Types.Rarity.Epic)
	for i in CalibrationTrait.MAX_CHARGES + 3:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	assert_eq(_trait._charges, CalibrationTrait.MAX_CHARGES,
		"Charges must not exceed MAX_CHARGES")

func test_unknown_skill_does_not_change_charges() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Fireball", {}, _resolver)
	assert_eq(_trait._charges, 0, "Unknown skill should leave charges unchanged")

func test_start_of_battle_resets_charges() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.StartOfBattle(0, _resolver)
	assert_eq(_trait._charges, 0)

func test_zone_used_grants_one_charge() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnZoneUsed(0, 1, _resolver)
	assert_eq(_trait._charges, 1)

func test_zone_used_capped_at_max() -> void:
	_InitTrait(Types.Rarity.Epic)
	for i in CalibrationTrait.MAX_CHARGES + 3:
		_trait.OnZoneUsed(0, 1, _resolver)
	assert_eq(_trait._charges, CalibrationTrait.MAX_CHARGES,
		"Charges must not exceed MAX_CHARGES from zone use either")

# --- Final Calculation consumption ---

func test_final_calculation_damage_multiplier_scales_with_charges_and_rarity() -> void:
	_InitTrait(Types.Rarity.Legendary)  # 10% per charge
	for i in 3:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	var result: TraitSkillResult = _trait.OnSkillCast(0, [1], "Final Calculation", {}, _resolver)
	assert_almost_eq(result._damage_multiplier, 1.0 + 3 * 0.10, 0.0001,
		"Three charges at Legendary should add 3 x 10% to the base multiplier")

func test_final_calculation_below_threshold_applies_no_debuff() -> void:
	_InitTrait(Types.Rarity.Epic)
	var target: Character = Character.new()
	target._current_health = 10
	_characters[1] = target
	for i in CalibrationTrait.EXPOSE_WEAKNESS_THRESHOLD - 1:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [1], "Final Calculation", {}, _resolver)
	assert_eq(target._active_debuffs.size(), 0,
		"Below the Expose Weakness threshold, no debuff should be applied")

func test_final_calculation_at_threshold_applies_expose_weakness() -> void:
	_InitTrait(Types.Rarity.Epic)
	var target: Character = Character.new()
	target._current_health = 10
	_characters[1] = target
	for i in CalibrationTrait.EXPOSE_WEAKNESS_THRESHOLD:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [1], "Final Calculation", {}, _resolver)
	assert_eq(target._active_debuffs.size(), 1)
	assert_eq(target._active_debuffs[0].type, Types.Debuff_Type.Expose_Weakness)
	assert_eq(target._active_debuffs[0].duration, CalibrationTrait.EXPOSE_WEAKNESS_DURATION)

func test_final_calculation_consumes_all_charges() -> void:
	_InitTrait(Types.Rarity.Epic)
	var target: Character = Character.new()
	target._current_health = 10
	_characters[1] = target
	for i in 5:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [1], "Final Calculation", {}, _resolver)
	assert_eq(_trait._charges, 0)

func test_final_calculation_with_zero_charges_deals_base_damage_only() -> void:
	_InitTrait(Types.Rarity.Epic)
	var result: TraitSkillResult = _trait.OnSkillCast(0, [1], "Final Calculation", {}, _resolver)
	assert_almost_eq(result._damage_multiplier, 1.0, 0.0001,
		"Zero charges should leave the base multiplier unchanged")

# --- Final Calculation tier 3: construction zone re-erect / upgrade ---

func test_final_calculation_below_tier_three_does_not_place_a_zone() -> void:
	_InitTrait(Types.Rarity.Epic)
	for i in CalibrationTrait.ZONE_RE_ERECT_THRESHOLD - 1:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [], "Final Calculation", {}, _resolver)
	assert_true(_resolver.GetZones().is_empty(),
		"Below the zone re-erect threshold, no zone should appear")

func test_final_calculation_at_tier_three_erects_a_zone_when_none_exists() -> void:
	_InitTrait(Types.Rarity.Epic)
	for i in CalibrationTrait.ZONE_RE_ERECT_THRESHOLD:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [], "Final Calculation", {}, _resolver)
	var zones: Dictionary[int, Zone] = _resolver.GetZones()
	assert_eq(zones.size(), 1, "A construction zone should be re-erected for free")
	var zone: Zone = zones.values()[0]
	assert_eq(zone._owner_ID, 0)
	assert_eq(zone._type, Types.Skill_Type.Barrier_Zone)
	assert_eq(zone._duration, CalibrationTrait.RAISE_THE_FRAME_ZONE_CHARGES)

func test_final_calculation_at_tier_three_upgrades_an_existing_zone() -> void:
	_InitTrait(Types.Rarity.Epic)
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Barrier_Zone
	zone_skill.duration = 2
	_resolver.PlaceZone(0, 0, zone_skill)

	for i in CalibrationTrait.ZONE_RE_ERECT_THRESHOLD:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [], "Final Calculation", {}, _resolver)

	var zones: Dictionary[int, Zone] = _resolver.GetZones()
	assert_eq(zones.size(), 1, "The existing zone should be upgraded, not duplicated")
	assert_eq(zones[0]._duration, CalibrationTrait.ZONE_UPGRADE_CHARGES)

func test_final_calculation_upgrading_an_existing_zone_emits_a_duration_result() -> void:
	_InitTrait(Types.Rarity.Epic)
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Barrier_Zone
	zone_skill.duration = 2
	_resolver.PlaceZone(0, 0, zone_skill)

	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	for i in CalibrationTrait.ZONE_RE_ERECT_THRESHOLD:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [], "Final Calculation", {}, _resolver)

	var duration_results: Array = received.filter(
		func(p_result): return p_result.kind == CombatResult.Kind.Zone_Duration_Changed)
	assert_eq(duration_results.size(), 1,
		"Upgrading an existing zone should notify listeners so the turn bar label updates")
	assert_eq(duration_results[0].zone_ID, 0)
	assert_eq(duration_results[0].duration, CalibrationTrait.ZONE_UPGRADE_CHARGES)

# --- Raise the Frame: charge consumption ---

func test_raise_the_frame_consumes_up_to_the_cap() -> void:
	_InitTrait(Types.Rarity.Epic)
	for i in CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP + 2:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [], "Raise the Frame", {}, _resolver)
	assert_eq(_trait._charges, 2,
		"Raise the Frame should consume only up to the cap, leaving the remainder")

func test_raise_the_frame_below_cap_consumes_all_held_charges() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	_trait.OnSkillCast(0, [], "Raise the Frame", {}, _resolver)
	assert_eq(_trait._charges, 0)

func test_raise_the_frame_with_zero_charges_consumes_nothing() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Raise the Frame", {}, _resolver)
	assert_eq(_trait._charges, 0)

# --- Zone_Constructed: recording invested charges ---

func test_on_zone_constructed_records_capped_invested_charges() -> void:
	_InitTrait(Types.Rarity.Epic)
	_character._trait = _trait
	for i in CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP + 4:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Barrier_Zone
	zone_skill.duration = 5
	_resolver.PlaceZone(0, 0, zone_skill)
	assert_eq(_trait._charges_invested_per_zone.get(0, -1), CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP,
		"Invested amount should be capped, independent of charges actually consumed")
	assert_eq(_trait._charges, CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP + 4,
		"OnZoneConstructed should only record, never consume")

func test_on_zone_constructed_ignores_non_barrier_zones() -> void:
	_InitTrait(Types.Rarity.Epic)
	_character._trait = _trait
	_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Flicker_Zone
	zone_skill.duration = 5
	_resolver.PlaceZone(0, 0, zone_skill)
	assert_false(_trait._charges_invested_per_zone.has(0),
		"Non-Barrier zones should not record an invested amount")

# --- GetZoneChargeBonus ---

func test_get_zone_charge_bonus_scales_with_invested_charges_and_potency() -> void:
	_InitTrait(Types.Rarity.Legendary) # 10% per charge
	_character._trait = _trait
	for i in CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP:
		_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Barrier_Zone
	zone_skill.duration = 5
	_resolver.PlaceZone(0, 0, zone_skill)
	assert_almost_eq(_trait.GetZoneChargeBonus(0), CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP * 0.10, 0.0001)

func test_get_zone_charge_bonus_is_zero_for_unknown_zone() -> void:
	_InitTrait(Types.Rarity.Legendary)
	assert_eq(_trait.GetZoneChargeBonus(0), 0.0)

# --- StartOfBattle clears per-zone record ---

func test_start_of_battle_clears_invested_charges() -> void:
	_InitTrait(Types.Rarity.Epic)
	_character._trait = _trait
	_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Barrier_Zone
	zone_skill.duration = 5
	_resolver.PlaceZone(0, 0, zone_skill)
	assert_gt(_trait.GetZoneChargeBonus(0), 0.0, "Sanity check: the zone's investment was recorded")
	_trait.StartOfBattle(0, _resolver)
	assert_eq(_trait.GetZoneChargeBonus(0), 0.0)
