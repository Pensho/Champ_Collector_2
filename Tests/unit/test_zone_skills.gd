extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

## Coverage for the zone-placement and zone-scaling skills (Catalyst Cloud, Unstable
## Rift, Temporal Sinkhole, Miasma, Weight of Law, Inscribe, Cataclysmic Surge,
## Inscription Surge), cast through the real ResolveSkill pipeline so the shipped .tres
## data (charges, target filtering, on_trigger effects) is exercised end to end rather
## than hand-built SkillEffects.

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _cast(p_caster_ID: int, p_skill_path: String, p_target_IDs: Array[int] = [],
		p_pending_zone_section: int = -1) -> void:
	var skill: Skill = load(p_skill_path).duplicate(true)
	_roster[p_caster_ID]._skills = [skill]
	if(-1 != p_pending_zone_section):
		_resolver.SetPendingZoneSection(p_pending_zone_section)
	_resolver.ResolveSkill(p_caster_ID, p_target_IDs, 0)

func _has_debuff(p_character_ID: int, p_type: Types.Debuff_Type) -> bool:
	for debuff in _roster[p_character_ID]._active_debuffs:
		if(p_type == debuff.type):
			return true
	return false

func _has_buff(p_character_ID: int, p_type: Types.Buff_Type) -> bool:
	for buff in _roster[p_character_ID]._active_buffs:
		if(p_type == buff.type):
			return true
	return false

func test_catalyst_cloud_places_a_four_charge_zone_and_buffs_the_ally_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [1]

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Catalyst_Cloud.tres", [], 0)

	assert_true(_has_buff(1, Types.Buff_Type.Catalyst), "The ally standing in the zone should gain Catalyst")
	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 3,
		"4 charges minus the one immediate trigger")

func test_unstable_rift_splits_damage_and_warps_both_sides_while_dealing_more_to_the_enemy() -> void:
	_positions.occupants_by_zone[0] = [1, 3]
	_roster[0]._attributes[Types.Attribute.Mysticism] = 200
	_roster[1]._attributes[Types.Attribute.Health] = 100000
	_roster[1]._current_health = 100000
	_roster[3]._attributes[Types.Attribute.Health] = 100000
	_roster[3]._current_health = 100000
	var ally_health_before: int = _roster[1]._current_health
	var enemy_health_before: int = _roster[3]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Unstable_Rift.tres", [], 0)

	assert_true(_has_debuff(1, Types.Debuff_Type.Warped), "The affected ally should be Warped")
	assert_true(_has_debuff(3, Types.Debuff_Type.Warped), "The affected enemy should be Warped")
	var ally_damage: int = ally_health_before - _roster[1]._current_health
	var enemy_damage: int = enemy_health_before - _roster[3]._current_health
	assert_gt(ally_damage, 0)
	assert_gt(enemy_damage, ally_damage, "The enemy's 30% share should deal more damage than the ally's 15% share")

func test_temporal_sinkhole_only_drains_the_enemy_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [1, 3]
	var results: Array[CombatResult] = []
	_resolver.result_produced.connect(func(r: CombatResult) -> void: results.append(r))

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Temporal_Sinkhole.tres", [], 0)

	var bumps: Array[CombatResult] = results.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump)
	var affected_IDs: Array[int] = []
	for bump in bumps:
		affected_IDs.append(bump.target_ID)
	assert_true(affected_IDs.has(3), "The enemy standing in the zone should have its turn bar drained")
	assert_false(affected_IDs.has(1), "The ally standing in the same zone must not be affected")

func test_miasma_applies_plague_to_the_enemy_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [3]

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Miasma.tres", [], 0)

	assert_true(_has_debuff(3, Types.Debuff_Type.Plague))

func test_weight_of_law_stuns_the_enemy_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [3]

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Weight_of_Law.tres", [], 0)

	assert_true(_has_debuff(3, Types.Debuff_Type.Stun))

func test_inscribe_damages_its_cast_target_and_places_a_left_most_glyph_that_damages_and_warps_visitors() -> void:
	_positions.occupants_by_zone[0] = [4]
	var target_health_before: int = _roster[3]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Inscribe.tres", [3])

	assert_lt(_roster[3]._current_health, target_health_before, "The direct cast target should take damage")
	assert_true(_resolver.GetZoneResolver().HasZone(0), "The glyph should land in the left-most empty section")
	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 2,
		"3 charges minus the one immediate trigger on the visitor")
	assert_true(_has_debuff(4, Types.Debuff_Type.Warped), "A visitor to the glyph should be Warped")

func test_cataclysmic_surge_deals_more_damage_to_a_warped_target() -> void:
	var warped: StatusEffects.Debuff = StatusEffects.Debuff.new()
	warped.type = Types.Debuff_Type.Warped
	warped.duration = 2
	_roster[3]._active_debuffs.append(warped)
	var warped_health_before: int = _roster[3]._current_health
	var plain_health_before: int = _roster[4]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Cataclysmic_Surge.tres", [3, 4, 5])

	var warped_damage: int = warped_health_before - _roster[3]._current_health
	var plain_damage: int = plain_health_before - _roster[4]._current_health
	assert_gt(warped_damage, plain_damage, "The Warped target should take 30% more damage than an unaffected one")

func _boost_caster_and_targets() -> void:
	_roster[0]._attributes[Types.Attribute.Mysticism] = 200
	for id in [3, 4, 5]:
		_roster[id]._attributes[Types.Attribute.Health] = 100000
		_roster[id]._current_health = 100000

func test_inscription_surge_deals_more_damage_with_zones_standing_on_the_bar() -> void:
	_boost_caster_and_targets()
	var baseline_before: int = _roster[3]._current_health
	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Inscription_Surge.tres", [3, 4, 5])
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	_boost_caster_and_targets()
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(1), Types.Skill_Target.ZoneAll)
	var zoned_before: int = _roster[3]._current_health
	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Inscription_Surge.tres", [3, 4, 5])
	var zoned_damage: int = zoned_before - _roster[3]._current_health

	assert_gt(zoned_damage, baseline_damage, "A zone standing on the bar should add 30% damage")
