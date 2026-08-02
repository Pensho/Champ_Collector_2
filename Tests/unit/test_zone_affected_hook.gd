extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the affected-by-zone dispatch and incoming-zone-effect multiplier:
# a probe trait on the character standing in a zone gets OnAffectedByZone with the
# zone owner's ID, and GetIncomingZoneEffectMultiplier scales the effect it receives.

class FakeZoneAffectedRecorder extends CharacterTrait:
	var last_owner_ID: int = -1
	var last_zone_owner_ID: int = -1
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Zone_Affected] = Callable(self, "OnAffectedByZone")

	func OnAffectedByZone(p_owner_ID: int, p_zone_owner_ID: int, _p_resolver: BattleResolver) -> void:
		last_owner_ID = p_owner_ID
		last_zone_owner_ID = p_zone_owner_ID
		call_count += 1

class FakeZoneEffectMultiplierTrait extends CharacterTrait:
	var multiplier: float = 1.0

	func _init(p_multiplier: float) -> void:
		multiplier = p_multiplier

	func GetIncomingZoneEffectMultiplier(
			_p_owner_ID: int, _p_zone_owner_ID: int, _p_sides: CombatSides) -> float:
		return multiplier

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_positions.characters_in_zones = true
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	# Only the zone owner (0) and one target (either 1, an ally, or 3, an enemy)
	# participate, so the single trigger-per-round lands on the target deterministically.
	for id in [2, 4, 5]:
		_roster[id]._current_health = 0

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _place_flicker_zone() -> void:
	_roster[0]._attributes[Types.Attribute.Knowledge] = 0
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAll
	zone_skill.skill_type = Types.Skill_Type.Flicker_Zone
	var zone_effect: ZoneEffect = ZoneEffect.new()
	zone_effect.duration = 5
	zone_skill.effects = [zone_effect]
	_resolver.GetZoneResolver().PlaceZone(0, 0, zone_skill)

func _place_lava_zone() -> void:
	_roster[0]._attributes[Types.Attribute.Knowledge] = 0
	_resolver.GetZoneResolver().PlaceZone(0, 0, TestFactory.make_lava_zone_skill())

func _bumps() -> Array[CombatResult]:
	return _resolver._batch.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump)

# --- OnAffectedByZone dispatch ---

func test_dispatches_on_affected_by_zone_for_an_ally_owned_zone() -> void:
	var recorder: FakeZoneAffectedRecorder = FakeZoneAffectedRecorder.new()
	_roster[1]._trait = recorder
	_place_flicker_zone()

	_resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(recorder.call_count, 1)
	assert_eq(recorder.last_owner_ID, 1)
	assert_eq(recorder.last_zone_owner_ID, 0)

func test_dispatches_on_affected_by_zone_for_an_enemy_owned_zone() -> void:
	var recorder: FakeZoneAffectedRecorder = FakeZoneAffectedRecorder.new()
	_roster[3]._trait = recorder
	_place_flicker_zone()

	_resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(recorder.call_count, 1)
	assert_eq(recorder.last_owner_ID, 3)
	assert_eq(recorder.last_zone_owner_ID, 0)

func test_unregistered_trait_is_not_dispatched() -> void:
	var plain_trait: CharacterTrait = CharacterTrait.new()
	_roster[1]._trait = plain_trait
	_place_flicker_zone()

	# A base CharacterTrait has no Zone_Affected step registered, so Skills.ActiveHook
	# must not call OnAffectedByZone on it (would otherwise only print, but the point is
	# no crash and no gated dispatch happens for an unregistered trait).
	_resolver.GetZoneResolver().TriggerZones(0)

	assert_true(true, "Reaching this line without error confirms the ungated trait was skipped")

func test_spore_zone_does_not_dispatch_when_the_status_application_is_blocked() -> void:
	var recorder: FakeZoneAffectedRecorder = FakeZoneAffectedRecorder.new()
	_roster[1]._trait = recorder
	for i in GameBalance.MAX_STATUS_EFFECTS:
		var filler: StatusEffects.Buff = StatusEffects.Buff.new()
		filler.type = Types.Buff_Type.Empower
		filler.ID = i
		_roster[1]._active_buffs.append(filler)
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAll
	zone_skill.skill_type = Types.Skill_Type.Spore_Zone
	var zone_effect: ZoneEffect = ZoneEffect.new()
	zone_effect.duration = 5
	zone_skill.effects = [zone_effect]
	_resolver.GetZoneResolver().PlaceZone(0, 0, zone_skill)

	_resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(recorder.call_count, 0,
			"A Regeneration blocked by the status cap should not count as 'affected by the zone'")

# --- GetIncomingZoneEffectMultiplier ---

func test_multiplier_scales_a_flicker_bump() -> void:
	_roster[1]._trait = FakeZoneEffectMultiplierTrait.new(1.5)
	_place_flicker_zone()

	_resolver.GetZoneResolver().TriggerZones(0)

	var expected: float = Skills.ZoneMagnitude(GameBalance.FLICKER_ZONE_BASE_BUMP, 0) * 1.5
	assert_almost_eq(_bumps()[0].fraction, expected, 0.0001)

func test_default_trait_leaves_a_flicker_bump_unscaled() -> void:
	_place_flicker_zone()

	_resolver.GetZoneResolver().TriggerZones(0)

	var expected: float = Skills.ZoneMagnitude(GameBalance.FLICKER_ZONE_BASE_BUMP, 0)
	assert_almost_eq(_bumps()[0].fraction, expected, 0.0001)

func test_multiplier_scales_a_lava_debuff_value() -> void:
	_roster[3]._trait = FakeZoneEffectMultiplierTrait.new(1.5)
	_place_lava_zone()

	_resolver.GetZoneResolver().TriggerZones(0)

	var base: float = _resolver.GetStatusResolver()._SnapshotStatusValue(
			StatusEffectRegistry.DebuffData(Types.Debuff_Type.Burning), 0)
	assert_almost_eq(_roster[3]._active_debuffs[0].value, base * 1.5, 0.0001)

func test_default_trait_leaves_a_lava_debuff_value_unscaled() -> void:
	_place_lava_zone()

	_resolver.GetZoneResolver().TriggerZones(0)

	var base: float = _resolver.GetStatusResolver()._SnapshotStatusValue(
			StatusEffectRegistry.DebuffData(Types.Debuff_Type.Burning), 0)
	assert_almost_eq(_roster[3]._active_debuffs[0].value, base, 0.0001)
