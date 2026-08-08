extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for CascadeResolver's own plumbing (Concept_Document.md 1.1.3/1.1.4): the two
# termination bounds, the once-per-action dedup rule, instance-count snapshotting, and the
# Cascade_Triggered stream marker. The three ported effects' own behavior (Overflow, Rush,
# Mirror Coat) stays covered by their existing suites — this file is the architecture, not
# the content.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _cascade: CascadeResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_cascade = _resolver.GetCascadeResolver()

# Plain int locals are captured by value inside a GDScript lambda — mutations inside the
# closure never propagate back out. A single-element Array is captured by reference, so
# it's the idiom used below (and already used for next_subject_ID) to observe run counts.

func test_depth_cap_refuses_a_chain_past_the_bound() -> void:
	var run_count: Array[int] = [0]
	var next_subject_ID: Array[int] = [0]
	var callback: Callable = func(p_event: CascadeEvent) -> void:
		run_count[0] += 1
		next_subject_ID[0] += 1
		var next_event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
		next_event.subject_ID = next_subject_ID[0]
		_cascade.Post(next_event)
	_cascade.Subscribe(Types.Cascade_Trigger.Status_Expired, &"SelfReentrant",
			func(_p_event: CascadeEvent) -> bool: return true, callback)

	_resolver._BeginBatch()
	var first_event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	first_event.subject_ID = 0
	_cascade.Post(first_event)
	_resolver._EndBatch()

	assert_eq(run_count[0], CascadeResolver.MAX_CASCADE_DEPTH,
		"A chain moving to a fresh subject each level must stop at the depth cap, not recurse forever")

func test_fan_out_cap_bounds_a_high_instance_count() -> void:
	var run_count: Array[int] = [0]
	_cascade.Subscribe(Types.Cascade_Trigger.Status_Expired, &"HighFanout",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: run_count[0] += 1)

	_resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = 0
	event.instance_count = CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION + 10
	_cascade.Post(event)
	_resolver._EndBatch()

	assert_eq(run_count[0], CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION,
		"A single trigger's instance count must not exceed the per-action fan-out cap")

func test_trigger_fires_once_per_action_but_yields_its_full_instance_count() -> void:
	var run_count: Array[int] = [0]
	_cascade.Subscribe(Types.Cascade_Trigger.Status_Expired, &"Repeatable",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: run_count[0] += 1)

	_resolver._BeginBatch()
	var first: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	first.subject_ID = 0
	first.instance_count = 3
	_cascade.Post(first)
	var second: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	second.subject_ID = 0
	second.instance_count = 5
	_cascade.Post(second)
	_resolver._EndBatch()

	assert_eq(run_count[0], 3,
		"The first firing's 3 instances should all run, but a second Post for the same " +
		"mechanic and subject in the same action must not fire again")

func test_snapshotted_instance_count_is_unaffected_by_later_mutation() -> void:
	var run_count: Array[int] = [0]
	_cascade.Subscribe(Types.Cascade_Trigger.Status_Expired, &"Snapshotted",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: run_count[0] += 1)
	var live_quantity: Dictionary[String, int] = {"remaining": 5}

	_resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = 0
	event.instance_count = live_quantity["remaining"]
	_cascade.Post(event)
	live_quantity["remaining"] = 0
	_resolver._EndBatch()

	assert_eq(run_count[0], 5,
		"An instance count fixed at Post time must not be affected by the live quantity draining")

func test_overflow_cascade_triggered_precedes_its_instance_and_carries_depth() -> void:
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Overflow
	buff.duration = 1
	_roster[0]._active_buffs.append(buff)
	_roster[0]._attributes[Types.Attribute.Mysticism] = 200

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)

	var triggered_index: int = -1
	var damage_index: int = -1
	for i in results.size():
		if(CombatResult.Kind.Cascade_Triggered == results[i].kind and -1 == triggered_index):
			triggered_index = i
		if(CombatResult.Kind.Damage == results[i].kind and -1 == damage_index):
			damage_index = i
	assert_ne(triggered_index, -1, "Overflow's expiry should emit a Cascade_Triggered marker")
	assert_ne(damage_index, -1, "Overflow's expiry should still deal damage")
	assert_lt(triggered_index, damage_index,
		"Cascade_Triggered must bracket the instance, landing immediately before its results")
	assert_eq(results[triggered_index].cascade_depth, 1,
		"A trigger fired directly from the originating action is cascade depth 1")
	assert_eq(results[damage_index].cascade_depth, 1,
		"Results produced inside the instance should carry the same depth as its marker")

func test_repeat_instances_each_read_live_conditions_via_a_fresh_combined_modifier() -> void:
	# A single alive enemy so each Overflow instance hits exactly one target once,
	# isolating cross-instance freshness from the per-target freshness _ResolveDamage
	# already exercises within a single instance.
	for id in [4, 5]:
		_roster[id]._current_health = 0
	# TestFactory characters start at a low flat current_health (not max-Health-scaled);
	# raise it so the target survives both instances regardless of exact damage rolls.
	_roster[3]._current_health = 1000
	_roster[0]._attributes[Types.Attribute.Mysticism] = 200
	var daunting_strength: StatusEffects.Buff = StatusEffects.Buff.new()
	daunting_strength.type = Types.Buff_Type.Daunting_Strength
	daunting_strength.duration = 5
	daunting_strength.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Daunting_Strength).magnitude
	_roster[0]._active_buffs.append(daunting_strength)

	_resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = 0
	event.buff_type = Types.Buff_Type.Overflow
	event.instance_count = 2
	_cascade.Post(event)
	var results: Array[CombatResult] = _resolver._EndBatch()

	var damage_amounts: Array[int] = []
	damage_amounts.assign(results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind
	).map(func(r: CombatResult) -> int: return r.amount))
	assert_eq(damage_amounts.size(), 2, "Both instances should deal damage to the one alive enemy")
	assert_gt(damage_amounts[0], damage_amounts[1],
		"The first instance should consume Daunting_Strength; a modifier cached across " +
		"instances would let the second instance keep benefiting from an already-consumed buff")
