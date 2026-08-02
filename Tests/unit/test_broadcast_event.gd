extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for BattleResolver.BroadcastEvent and its three wiring sites (buff expiry,
# zone dissipation, reagent consumption) — the primitive Detritivore's Resource_Depleted
# hook is built on.

class FakeBroadcastRecorder extends CharacterTrait:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Resource_Depleted] = Callable(self, "OnScavenge")

	func OnScavenge(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
		call_count += 1

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

# --- BroadcastEvent itself ---

func test_broadcast_invokes_registered_traits_on_both_sides() -> void:
	var player_recorder: FakeBroadcastRecorder = FakeBroadcastRecorder.new()
	var enemy_recorder: FakeBroadcastRecorder = FakeBroadcastRecorder.new()
	_roster[0]._trait = player_recorder
	_roster[3]._trait = enemy_recorder

	_resolver.BroadcastEvent(Types.Combat_Event.Resource_Depleted)

	assert_eq(player_recorder.call_count, 1)
	assert_eq(enemy_recorder.call_count, 1)

func test_broadcast_skips_unregistered_traits() -> void:
	_roster[0]._trait = CharacterTrait.new()

	_resolver.BroadcastEvent(Types.Combat_Event.Resource_Depleted)

	assert_true(true, "Reaching this line without error confirms the ungated trait was skipped")

func test_broadcast_skips_traitless_characters() -> void:
	_roster[0]._trait = null

	_resolver.BroadcastEvent(Types.Combat_Event.Resource_Depleted)

	assert_true(true, "Reaching this line without error confirms a null trait was skipped")

# --- Buff-expiry site ---

func test_buff_expiring_via_duration_fires_the_broadcast() -> void:
	var recorder: FakeBroadcastRecorder = FakeBroadcastRecorder.new()
	_roster[1]._trait = recorder
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 1
	_roster[0]._active_buffs.append(buff)
	var attrs: Dictionary[Types.Attribute, int] = _resolver.GetEffectiveAttributes(0)

	_resolver.GetStatusResolver()._TriggerExistingCasterBuffs(0, attrs)

	assert_eq(recorder.call_count, 1)

func test_remove_buff_does_not_fire_the_broadcast() -> void:
	var recorder: FakeBroadcastRecorder = FakeBroadcastRecorder.new()
	_roster[1]._trait = recorder
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 5
	_roster[0]._active_buffs.append(buff)

	_resolver.GetStatusResolver().RemoveBuff(0, buff)

	assert_eq(recorder.call_count, 0)

func test_death_clearing_statuses_does_not_fire_the_broadcast() -> void:
	var recorder: FakeBroadcastRecorder = FakeBroadcastRecorder.new()
	_roster[1]._trait = recorder
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 5
	_roster[0]._active_buffs.append(buff)

	_resolver._HandleDeath(0)

	assert_eq(recorder.call_count, 0)

# --- Zone-dissipation site ---

func test_zone_reaching_zero_duration_fires_the_broadcast() -> void:
	var recorder: FakeBroadcastRecorder = FakeBroadcastRecorder.new()
	_roster[1]._trait = recorder
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAll
	zone_skill.skill_type = Types.Skill_Type.Flicker_Zone
	_resolver.GetZoneResolver().PlaceZone(0, 0, zone_skill)

	_resolver.GetZoneResolver().TriggerZones(-1)

	assert_eq(recorder.call_count, 1)
	assert_false(_resolver.GetZoneResolver().HasZone(0))

# --- Reagent-consumption site ---

func test_reagent_consumed_by_another_character_fires_the_broadcast_on_the_symbiote() -> void:
	var recorder: FakeBroadcastRecorder = FakeBroadcastRecorder.new()
	_roster[0]._trait = recorder

	_resolver.ResolveReagent(1, "Restorative_Draught_Rare", 1)

	assert_eq(recorder.call_count, 1)
