extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for CascadeResolver's own plumbing (Concept_Document.md 1.1.3/1.1.4): the two
# termination bounds, the once-per-action dedup rule, instance-count snapshotting, the
# Cascade_Triggered stream marker, the contributor/attribution model, and the per-instance
# Cascade_Instance_Resolved notification. The three ported effects' own behavior (Overflow,
# Rush, Mirror Coat) stays covered by their existing suites — this file is the architecture,
# not the content.

class FakeCascadeInstanceListenerTrait extends CharacterTrait:
	var _notified_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Cascade_Instance_Resolved] = Callable(self, "OnCascadeInstanceResolved")

	func OnCascadeInstanceResolved(
			_p_owner_ID: int, _p_event: CascadeEvent, _p_resolver: BattleResolver) -> void:
		_notified_count += 1

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
	_cascade.SubscribeDeferredTrigger(Types.Cascade_Trigger.Status_Expired, &"SelfReentrant",
			func(_p_event: CascadeEvent) -> bool: return true, callback)

	_resolver._BeginBatch()
	var first_event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	first_event.subject_ID = 0
	_cascade.Post(first_event)
	_resolver._EndBatch()

	assert_eq(run_count[0], CascadeResolver.MAX_CASCADE_DEPTH,
		"A chain moving to a fresh subject each level must stop at the depth cap, not recurse forever")

func test_deferred_trigger_fan_out_cap_bounds_a_high_instance_count() -> void:
	var run_count: Array[int] = [0]
	_cascade.SubscribeDeferredTrigger(Types.Cascade_Trigger.Status_Expired, &"HighFanout",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: run_count[0] += 1)

	_resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = 0
	event.instance_count = CascadeResolver.MAX_DEFERRED_TRIGGER_INSTANCES_PER_ACTION + 10
	_cascade.Post(event)
	_resolver._EndBatch()

	assert_eq(run_count[0], CascadeResolver.MAX_DEFERRED_TRIGGER_INSTANCES_PER_ACTION,
		"A single deferred trigger's instance count must not exceed its own fan-out cap, " +
		"which is not shared with Channel 3's MAX_CASCADE_INSTANCES_PER_ACTION")

func test_trigger_fires_once_per_action_but_yields_its_full_instance_count() -> void:
	var run_count: Array[int] = [0]
	_cascade.SubscribeDeferredTrigger(Types.Cascade_Trigger.Status_Expired, &"Repeatable",
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
	_cascade.SubscribeDeferredTrigger(Types.Cascade_Trigger.Status_Expired, &"Snapshotted",
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

func test_overflow_expiry_emits_no_burst_marker_and_stamps_depth_zero() -> void:
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
	assert_eq(triggered_index, -1,
		"Overflow is a deferred trigger, not a Channel 3 mechanic, and must not emit a Cascade_Triggered marker")
	assert_ne(damage_index, -1, "Overflow's expiry should still deal damage")
	assert_eq(results[damage_index].cascade_depth, 0,
		"Overflow's damage resolves outside any Echo, so it carries the base-hit depth of 0")

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

func test_a_cascade_posted_from_inside_a_trait_local_echo_is_stamped_depth_2() -> void:
	assert_true(_resolver.BeginEchoInstance(&"FakeTraitLocalRepeat", 0, Types.Cascade_Trigger.Skill_Resolved),
		"Sanity check: the trait-local Echo should open")
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = 0
	_cascade.Post(event)
	_resolver.EndEchoInstance()

	assert_eq(event.depth, 2,
		"A trait-local repeat resolves at depth 1, so a cascade it posts must be stamped depth 2")

func test_begin_echo_instance_refuses_once_the_fan_out_cap_is_spent() -> void:
	_resolver._echoes_this_action = CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION
	assert_false(_resolver.BeginEchoInstance(&"FakeTraitLocalRepeat", 0, Types.Cascade_Trigger.Skill_Resolved),
		"BeginEchoInstance must refuse once the shared per-action Echo budget is spent")

func test_contributor_base_alone_creates_a_cascade() -> void:
	var run_count: Array[int] = [0]
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"BaseContributor", 2, CascadeContribution.Kind.Base,
				1.0, func(_e: CascadeEvent) -> void: run_count[0] += 1))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	assert_eq(run_count[0], 2, "A Base contributor's own instances should resolve on their own")

func test_contributor_base_with_no_resolve_falls_back_to_the_canonical_skill_replay() -> void:
	_roster[0]._skills.append(TestFactory.make_strike_skill())
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"NoResolve", 1, CascadeContribution.Kind.Base, 1.0))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, [3]))
	var results: Array[CombatResult] = _resolver._EndBatch()

	var damage_results: Array[CombatResult] = results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind)
	assert_false(damage_results.is_empty(),
		"A Base contribution with no resolve should fall back to ResolveSkillEcho and deal damage")

func test_contributor_extender_without_a_base_contributes_nothing() -> void:
	var run_count: Array[int] = [0]
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"ExtenderOnly", 3, CascadeContribution.Kind.Extender,
				1.0, func(_e: CascadeEvent) -> void: run_count[0] += 1))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	assert_eq(run_count[0], 0, "An extender cannot enable a cascade with no Base contributing")

func test_contributor_extender_appends_to_the_dominant_base() -> void:
	var base_runs: Array[int] = [0]
	var extender_runs: Array[int] = [0]
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"Dominant", 2, CascadeContribution.Kind.Base,
				1.0, func(_e: CascadeEvent) -> void: base_runs[0] += 1))
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"MinorExtender", 1, CascadeContribution.Kind.Extender,
				1.0, func(_e: CascadeEvent) -> void: extender_runs[0] += 1))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	assert_eq(base_runs[0], 3,
		"The dominant Base's slice should absorb the Extender's instance and resolve at its own strength")
	assert_eq(extender_runs[0], 0,
		"An Extender never runs its own resolve — its instance is folded into the Base's slice")

## An Extender contributing to no Base must not spend its per-action dedup slot: the mechanic
## it stands for should still be free to extend a later Base in the same action.
func test_extender_without_a_base_does_not_burn_its_dedup_slot() -> void:
	var base_runs: Array[int] = [0]
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"LonelyExtender", 1, CascadeContribution.Kind.Extender))
	# Only fires for the second event, standing in for a Base that does not exist yet
	# when the Extender is first queried.
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		if(2 != _p_event.skill_ID):
			return null
		return CascadeContribution.new(&"LateBase", 1, CascadeContribution.Kind.Base,
				1.0, func(_e: CascadeEvent) -> void: base_runs[0] += 1))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 1, []))  # no Base yet: the Extender contributes nothing
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 2, []))  # a Base now exists, in the same action
	_resolver._EndBatch()

	assert_eq(base_runs[0], 2,
		"The Base should resolve once for itself and once for the Extender's appended instance")

func test_contributor_respects_the_once_per_action_dedup() -> void:
	var run_count: Array[int] = [0]
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"Repeatable", 1, CascadeContribution.Kind.Base,
				1.0, func(_e: CascadeEvent) -> void: run_count[0] += 1))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	assert_eq(run_count[0], 1,
		"A second Skill_Resolved event for the same mechanic and subject in one action must not fire again")

func test_echo_strength_contributions_are_visible_during_the_instance_and_restored_after() -> void:
	assert_eq(_resolver.CurrentEchoStrengthContributions(), {},
		"No Echo is resolving, so there should be no strength contributions")

	_resolver.BeginEchoInstance(&"Outer", 0, Types.Cascade_Trigger.Skill_Resolved, 0, {&"Outer": 0.5})
	assert_eq(_resolver.CurrentEchoStrengthContributions(), {&"Outer": 0.5},
		"The contributions passed to BeginEchoInstance should be visible while it resolves")

	_resolver.BeginEchoInstance(&"Inner", 0, Types.Cascade_Trigger.Skill_Resolved, 0, {&"Inner": 0.25})
	assert_eq(_resolver.CurrentEchoStrengthContributions(), {&"Inner": 0.25},
		"A nested Echo's own contributions should apply while it resolves, not the outer one's")
	_resolver.EndEchoInstance()

	assert_eq(_resolver.CurrentEchoStrengthContributions(), {&"Outer": 0.5},
		"Ending the inner Echo should restore the outer Echo's contributions")
	_resolver.EndEchoInstance()

	assert_eq(_resolver.CurrentEchoStrengthContributions(), {},
		"Ending the outermost Echo should leave no strength contributions active")

func test_strength_modifiers_do_not_reach_a_deferred_trigger() -> void:
	var seen_contributions: Array[Dictionary] = []
	_cascade.SubscribeDeferredTrigger(Types.Cascade_Trigger.Status_Expired, &"DeferredMechanic",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void:
				seen_contributions.append(_resolver.CurrentEchoStrengthContributions()))
	_cascade.SubscribeStrengthModifier(func(_p_event: CascadeEvent) -> CascadeStrength:
		return CascadeStrength.new(&"SomeModifier", 1.5))

	_resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = 0
	_cascade.Post(event)
	_resolver._EndBatch()

	assert_eq(seen_contributions, [{}],
		"A deferred trigger produces no Echo, so a registered strength modifier must never reach it")

func test_strength_modifier_reaches_a_contributor_driven_echo() -> void:
	var seen_contributions: Array[Dictionary] = []
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"Contributor", 1, CascadeContribution.Kind.Base, 1.0,
				func(_e: CascadeEvent) -> void:
					seen_contributions.append(_resolver.CurrentEchoStrengthContributions())))
	_cascade.SubscribeStrengthModifier(func(_p_event: CascadeEvent) -> CascadeStrength:
		return CascadeStrength.new(&"Modifier", 1.5))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	assert_eq(seen_contributions, [{&"Modifier": 0.5}],
		"A strength modifier should reach a contributor-driven Echo too")

func test_two_strength_modifiers_sharing_a_key_compose_rather_than_clobber() -> void:
	var seen_contributions: Array[Dictionary] = []
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"Contributor", 1, CascadeContribution.Kind.Base, 1.0,
				func(_e: CascadeEvent) -> void:
					seen_contributions.append(_resolver.CurrentEchoStrengthContributions())))
	_cascade.SubscribeStrengthModifier(func(_p_event: CascadeEvent) -> CascadeStrength:
		return CascadeStrength.new(&"Shared", 1.5))
	_cascade.SubscribeStrengthModifier(func(_p_event: CascadeEvent) -> CascadeStrength:
		return CascadeStrength.new(&"Shared", 1.2))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	assert_eq(seen_contributions, [{&"Shared": 0.7}],
		"Two strength modifiers keyed the same must sum (0.5 + 0.2), not have the second overwrite the first")

func test_strength_modifier_returning_null_or_no_multiplier_contributes_nothing() -> void:
	var seen_contributions: Array[Dictionary] = []
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"Contributor", 1, CascadeContribution.Kind.Base, 1.0,
				func(_e: CascadeEvent) -> void:
					seen_contributions.append(_resolver.CurrentEchoStrengthContributions())))
	_cascade.SubscribeStrengthModifier(func(_p_event: CascadeEvent) -> CascadeStrength:
		return null)
	_cascade.SubscribeStrengthModifier(func(_p_event: CascadeEvent) -> CascadeStrength:
		return CascadeStrength.new(&"Inert", 1.0))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	assert_eq(seen_contributions, [{}],
		"A null modifier and one at multiplier 1.0 (no effect) should both contribute nothing")

## The governing rule: BeginEchoInstance is called from exactly one place, CascadeResolver's
## own instance loop. A script anywhere else that calls it has grown a private Echo loop
## instead of declaring a contribution.
func test_begin_echo_instance_is_called_only_from_cascade_resolver() -> void:
	var offending_files: Array[String] = []
	var directories: Array[String] = ["res://Scripts"]
	while(not directories.is_empty()):
		var directory_path: String = directories.pop_back()
		var directory: DirAccess = DirAccess.open(directory_path)
		assert_not_null(directory, "Could not open %s" % directory_path)
		directory.list_dir_begin()
		var entry: String = directory.get_next()
		while(not entry.is_empty()):
			var full_path: String = "%s/%s" % [directory_path, entry]
			if(directory.current_is_dir()):
				directories.append(full_path)
			elif(entry.ends_with(".gd") and "cascade_resolver.gd" != entry):
				var contents: String = FileAccess.get_file_as_string(full_path)
				for line in contents.split("\n"):
					var trimmed: String = line.strip_edges()
					if(trimmed.contains("BeginEchoInstance(") and not trimmed.begins_with("func BeginEchoInstance(")):
						offending_files.append(full_path)
						break
			entry = directory.get_next()
		directory.list_dir_end()

	assert_eq(offending_files, [],
		"Only cascade_resolver.gd may call BeginEchoInstance; a Channel 3 mechanic must " +
		"declare a CascadeContribution instead of opening its own Echo loop")

func test_cascade_instance_resolved_notifies_every_living_characters_trait() -> void:
	for id in _roster.keys():
		_roster[id]._trait = FakeCascadeInstanceListenerTrait.new()
		_roster[id]._trait.Init(Types.Rarity.Common)
	_roster[4]._current_health = 0
	_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"Notifier", 2, CascadeContribution.Kind.Base,
				1.0, func(_e: CascadeEvent) -> void: pass))

	_resolver._BeginBatch()
	_cascade.Post(CascadeEvent.ForSkillResolved(0, 0, []))
	_resolver._EndBatch()

	for id in _roster.keys():
		var observed: int = (_roster[id]._trait as FakeCascadeInstanceListenerTrait)._notified_count
		if(id == 4):
			assert_eq(observed, 0, "A dead character's trait must not be notified")
		else:
			assert_eq(observed, 2, "Every living character's trait should be notified once per real instance")

func test_deferred_trigger_does_not_notify_cascade_instance_resolved() -> void:
	for id in _roster.keys():
		_roster[id]._trait = FakeCascadeInstanceListenerTrait.new()
		_roster[id]._trait.Init(Types.Rarity.Common)
	_cascade.SubscribeDeferredTrigger(Types.Cascade_Trigger.Status_Expired, &"DeferredNotifier",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: pass)

	_resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = 0
	event.instance_count = 2
	_cascade.Post(event)
	_resolver._EndBatch()

	for id in _roster.keys():
		var observed: int = (_roster[id]._trait as FakeCascadeInstanceListenerTrait)._notified_count
		assert_eq(observed, 0,
			"A deferred trigger produces no Echo, so it must never fire Cascade_Instance_Resolved")
