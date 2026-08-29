extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Regression coverage for a bug class found while auditing the suite: several trait-hook
# dispatch sites fired on a character whose _current_health had already reached 0 earlier
# in the same resolution (a self-cost effect, a debuff tick, an earlier skill effect), since
# only some sites guarded on the owner/target still being alive. Buff_Applied/Debuff_Received/
# Debuff_Applied are covered in test_status_effect_hooks.gd; Zone_Affected is covered in
# test_zone_affected_hook.gd. This file covers the remaining sites: End_Turn, Defend,
# Damage_Taken, Damage_Dealt, Critical_Hit, Zone_Used.

class FakeEndOfTurnRecorder extends CharacterTrait:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.End_Turn] = Callable(self, "EndOfTurn")

	func EndOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
		call_count += 1

class FakeDefendRecorder extends CharacterTrait:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Defend] = Callable(self, "OnDefend")

	func OnDefend(
			_p_defender_ID: int, _p_defender_attributes: Dictionary[Types.Attribute, int],
			_p_characters: Dictionary[int, Character]) -> void:
		call_count += 1

class FakeDamageDealtRecorder extends CharacterTrait:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Damage_Dealt] = Callable(self, "OnDamageDealt")

	func OnDamageDealt(_p_owner_ID: int, _p_target_ID: int, _p_amount: int, _p_resolver: BattleResolver) -> void:
		call_count += 1

class FakeCriticalHitRecorder extends CharacterTrait:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Critical_Hit] = Callable(self, "OnCriticalHit")

	func OnCriticalHit(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> void:
		call_count += 1

class FakeZoneUsedRecorder extends CharacterTrait:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Zone_Used] = Callable(self, "OnZoneUsed")

	func OnZoneUsed(_p_owner_ID: int, _p_user_ID: int, _p_zone_ID: int, _p_resolver: BattleResolver) -> void:
		call_count += 1

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

# --- End_Turn ---

func test_end_of_turn_hook_does_not_fire_when_the_caster_dies_during_their_own_turn() -> void:
	var recorder: FakeEndOfTurnRecorder = FakeEndOfTurnRecorder.new()
	_roster[0]._trait = recorder
	_roster[0]._skills.append(TestFactory.make_empty_skill())
	_roster[0]._current_health = 1
	# A Bleed sourced from a high-Attack caster ticks for lethal damage during
	# _TriggerExistingCasterDebuffs, before ResolveSkill's own End_Turn dispatch.
	_roster[1]._attributes[Types.Attribute.Attack] = 9999
	var bleed: StatusEffects.Debuff = StatusEffects.Debuff.new()
	bleed.type = Types.Debuff_Type.Bleed
	bleed.duration = 2
	bleed.source_ID = 1
	_resolver.GetStatusResolver().ApplyDebuff(0, bleed)

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._current_health, 0, "The Bleed tick must actually be lethal for this test to be meaningful")
	assert_eq(recorder.call_count, 0, "A caster who died this turn must not receive End_Turn")

func test_end_of_turn_hook_does_not_fire_on_a_stunned_turn_for_an_already_dead_caster() -> void:
	var recorder: FakeEndOfTurnRecorder = FakeEndOfTurnRecorder.new()
	_roster[0]._trait = recorder
	_roster[0]._current_health = 0

	_resolver.ResolveStunTurn(0)

	assert_eq(recorder.call_count, 0, "A dead caster must not receive End_Turn on a stunned turn")

# --- Defend ---

func test_defend_hook_does_not_fire_on_a_dead_target() -> void:
	var recorder: FakeDefendRecorder = FakeDefendRecorder.new()
	_roster[3]._trait = recorder
	_roster[3]._current_health = 0

	_resolver.ResolveEffectDamage(0, 3, _resolver.GetEffectiveAttributes(0),
			{Types.Attribute.Attack: 1.0}, 1.0, CombinedDamageModifier.new())

	assert_eq(recorder.call_count, 0, "A dead target must not receive Defend")

# --- Damage_Taken ---

func test_damage_taken_hook_does_not_fire_on_a_dead_target() -> void:
	var recorder: TestFactory.FakeDamageTakenAttackerRecorder = TestFactory.FakeDamageTakenAttackerRecorder.new()
	_roster[3]._trait = recorder
	_roster[3]._current_health = 0

	_resolver.ResolveEffectDamage(0, 3, _resolver.GetEffectiveAttributes(0),
			{Types.Attribute.Attack: 1.0}, 1.0, CombinedDamageModifier.new())

	assert_eq(recorder.call_count, 0, "A dead target must not receive Damage_Taken")

# --- Damage_Dealt / Critical_Hit ---

func test_damage_dealt_and_critical_hit_hooks_do_not_fire_when_the_caster_is_dead() -> void:
	var damage_dealt_recorder: FakeDamageDealtRecorder = FakeDamageDealtRecorder.new()
	var critical_hit_recorder: FakeCriticalHitRecorder = FakeCriticalHitRecorder.new()
	# A single trait can only register one execution step per event, so use two casters
	# to probe both hooks against the same dead-caster setup.
	_roster[0]._trait = damage_dealt_recorder
	_roster[1]._trait = critical_hit_recorder
	_roster[0]._current_health = 0
	_roster[1]._current_health = 0
	var caster_attributes: Dictionary[Types.Attribute, int] = _resolver.GetEffectiveAttributes(0)
	caster_attributes[Types.Attribute.CritChance] = 1000

	_resolver.ResolveEffectDamage(0, 3, caster_attributes, {Types.Attribute.Attack: 1.0}, 1.0,
			CombinedDamageModifier.new())
	_resolver.ResolveEffectDamage(1, 4, caster_attributes, {Types.Attribute.Attack: 1.0}, 1.0,
			CombinedDamageModifier.new())

	assert_eq(damage_dealt_recorder.call_count, 0, "A dead caster must not receive Damage_Dealt")
	assert_eq(critical_hit_recorder.call_count, 0, "A dead caster must not receive Critical_Hit")

# --- Zone_Used ---

func test_zone_used_hook_does_not_fire_when_the_zone_owner_is_dead() -> void:
	var recorder: FakeZoneUsedRecorder = FakeZoneUsedRecorder.new()
	_roster[0]._trait = recorder
	_roster[0]._current_health = 0

	Skills.TriggerZoneUsedHook(_resolver.GetCharacters(), 0, 1, 0, _resolver)

	assert_eq(recorder.call_count, 0, "A dead zone owner must not receive Zone_Used")
