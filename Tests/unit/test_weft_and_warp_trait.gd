extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _trait: WeftAndWarpTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func before_each() -> void:
	_character = Character.new()
	_character._current_health = 10
	_character._attributes[Types.Attribute.Health] = 10
	_trait = WeftAndWarpTrait.new()
	_characters = {0: _character}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], []))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

# --- Battle start ---

func test_starts_on_silver_thread() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_trait._current_thread = WeftAndWarpTrait.Thread_Type.Black
	_trait.StartOfBattle(0, _resolver)
	assert_eq(_trait.GetCurrentThread(), WeftAndWarpTrait.Thread_Type.Silver)

func test_starting_tension_by_rarity() -> void:
	for entry in [
			[Types.Rarity.Uncommon, 0], [Types.Rarity.Rare, 0],
			[Types.Rarity.Epic, 1], [Types.Rarity.Legendary, 1]]:
		_InitTrait(entry[0])
		_trait._tension = 5
		_trait.StartOfBattle(0, _resolver)
		assert_eq(_trait._tension, entry[1], "Wrong starting Tension for rarity %s" % entry[0])

func test_tension_does_not_persist_between_combats() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._tension = WeftAndWarpTrait.TENSION_MAX
	_trait.StartOfBattle(0, _resolver)
	assert_eq(_trait._tension, 0)

# --- Thread switching ---

func test_advance_thread_cycles_silver_golden_black_silver() -> void:
	_InitTrait(Types.Rarity.Rare)
	assert_eq(_trait.GetCurrentThread(), WeftAndWarpTrait.Thread_Type.Silver)
	_trait.AdvanceThread()
	assert_eq(_trait.GetCurrentThread(), WeftAndWarpTrait.Thread_Type.Golden)
	_trait.AdvanceThread()
	assert_eq(_trait.GetCurrentThread(), WeftAndWarpTrait.Thread_Type.Black)
	_trait.AdvanceThread()
	assert_eq(_trait.GetCurrentThread(), WeftAndWarpTrait.Thread_Type.Silver)

func test_advance_thread_has_no_cap_on_calls_per_turn() -> void:
	_InitTrait(Types.Rarity.Rare)
	for i in 10:
		_trait.AdvanceThread()
	# 10 advances from Silver, cycling Silver -> Golden -> Black every 3 steps: 10 mod 3 == 1.
	assert_eq(_trait.GetCurrentThread(), WeftAndWarpTrait.Thread_Type.Golden)

# --- Silver Thread ---

func test_silver_extends_outgoing_debuff_duration() -> void:
	_InitTrait(Types.Rarity.Rare)
	assert_eq(_trait.GetOutgoingDebuffDurationBonus(0), 1)
	_trait.AdvanceThread()  # Golden
	assert_eq(_trait.GetOutgoingDebuffDurationBonus(0), 0)
	_trait.AdvanceThread()  # Black
	assert_eq(_trait.GetOutgoingDebuffDurationBonus(0), 0)

func test_silver_makes_debuffs_unresistable() -> void:
	_InitTrait(Types.Rarity.Rare)
	assert_true(_trait.DebuffsCannotBeResisted(0, 1))
	_trait.AdvanceThread()  # Golden
	assert_false(_trait.DebuffsCannotBeResisted(0, 1))

# --- Pull the Thread: stance-independent Tension grant ---

func test_pull_the_thread_grants_tension_regardless_of_thread() -> void:
	for i in 3:
		_InitTrait(Types.Rarity.Uncommon)
		_trait._tension = 0
		for j in i:
			_trait.AdvanceThread()
		_trait.OnSkillCast(0, [], "Pull the Thread", {}, _resolver)
		assert_eq(_trait._tension, WeftAndWarpTrait.PULL_THE_THREAD_TENSION,
			"Pull the Thread should grant Tension on thread index %d" % i)

func test_pull_the_thread_tension_caps_at_max() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._tension = WeftAndWarpTrait.TENSION_MAX - 1
	_trait.OnSkillCast(0, [], "Pull the Thread", {}, _resolver)
	assert_eq(_trait._tension, WeftAndWarpTrait.TENSION_MAX)

# --- Golden Thread: Tension from cascade instances ---

func test_golden_gains_tension_when_a_cascade_instance_resolves_on_an_enemy() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait.AdvanceThread()  # Golden
	var enemy: Character = TestFactory.make_character()
	_characters[1] = enemy
	var sided_resolver: BattleResolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 5
	event.target_IDs = [1]

	_trait.OnCascadeInstanceResolved(0, event, sided_resolver)

	assert_eq(_trait._tension, 1)

func test_golden_ignores_instances_not_concerning_an_enemy() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait.AdvanceThread()  # Golden
	var ally: Character = TestFactory.make_character()
	_characters[1] = ally
	var sided_resolver: BattleResolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1], []))
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 5
	event.target_IDs = [1]

	_trait.OnCascadeInstanceResolved(0, event, sided_resolver)

	assert_eq(_trait._tension, 0)

func test_golden_tension_caps_at_max() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait.AdvanceThread()  # Golden
	_trait._tension = WeftAndWarpTrait.TENSION_MAX
	var enemy: Character = TestFactory.make_character()
	_characters[1] = enemy
	var sided_resolver: BattleResolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 5
	event.target_IDs = [1]

	_trait.OnCascadeInstanceResolved(0, event, sided_resolver)

	assert_eq(_trait._tension, WeftAndWarpTrait.TENSION_MAX)

func test_golden_gains_no_tension_from_a_plain_debuff_tick_with_no_contributor() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait.AdvanceThread()  # Golden
	var enemy: Character = TestFactory.make_character()
	_characters[1] = enemy
	var sided_resolver: BattleResolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))
	sided_resolver.GetCascadeResolver().Post(CascadeEvent.new(Types.Cascade_Trigger.Debuff_Ticked))
	sided_resolver.GetCascadeResolver().Drain()

	assert_eq(_trait._tension, 0,
		"A plain debuff tick with no contributor should post but resolve no Echo, granting no Tension")

func test_non_golden_threads_do_not_gain_tension_from_cascade_instances() -> void:
	_InitTrait(Types.Rarity.Uncommon)  # Silver
	var enemy: Character = TestFactory.make_character()
	_characters[1] = enemy
	var sided_resolver: BattleResolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 5
	event.target_IDs = [1]

	_trait.OnCascadeInstanceResolved(0, event, sided_resolver)

	assert_eq(_trait._tension, 0)

# --- Black Thread: instance-count modifier via CascadeResolver ---

func _make_black_thread_setup() -> Dictionary:
	var caster: Character = TestFactory.make_character()
	caster._rarity = Types.Rarity.Rare
	var herald_trait: WeftAndWarpTrait = WeftAndWarpTrait.new()
	herald_trait.Init(Types.Rarity.Rare)
	caster._trait = herald_trait
	var enemy: Character = TestFactory.make_character()
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	# StartOfBattle resets the thread to Silver, so advance only after broadcasting it.
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	herald_trait.AdvanceThread()  # Golden
	herald_trait.AdvanceThread()  # Black
	return {"trait": herald_trait, "resolver": resolver}

## A Base contributor standing in for a real skill-replay mechanic (e.g. Cut the Cloth):
## Black Thread only extends a contributor-driven Base, never a raw Subscribe listener.
func _subscribe_test_base_contributor(p_cascade: CascadeResolver, p_run_count: Array[int]) -> void:
	p_cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		return CascadeContribution.new(&"TestBase", 1, CascadeContribution.Kind.Base, 1.0,
				func(_e: CascadeEvent) -> void: p_run_count[0] += 1))

func test_black_thread_grants_one_extra_instance_to_the_herald_own_cascade() -> void:
	var setup: Dictionary = _make_black_thread_setup()
	var resolver: BattleResolver = setup["resolver"]
	var cascade: CascadeResolver = resolver.GetCascadeResolver()
	var run_count: Array[int] = [0]
	_subscribe_test_base_contributor(cascade, run_count)

	resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 0
	event.target_IDs = [1]
	cascade.Post(event)
	resolver._EndBatch()

	assert_eq(run_count[0], 2, "Black Thread should add one extra instance to the Herald's own cascade")

func test_black_thread_does_not_affect_another_characters_cascade() -> void:
	var setup: Dictionary = _make_black_thread_setup()
	var resolver: BattleResolver = setup["resolver"]
	var cascade: CascadeResolver = resolver.GetCascadeResolver()
	var run_count: Array[int] = [0]
	_subscribe_test_base_contributor(cascade, run_count)

	resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 1  # not the Herald
	event.target_IDs = [0]
	cascade.Post(event)
	resolver._EndBatch()

	assert_eq(run_count[0], 1, "Black Thread must not amplify a cascade it did not cause")

func test_black_thread_does_not_extend_a_status_triggered_cascade() -> void:
	var setup: Dictionary = _make_black_thread_setup()
	var resolver: BattleResolver = setup["resolver"]
	var cascade: CascadeResolver = resolver.GetCascadeResolver()
	var run_count: Array[int] = [0]
	# A Base contributor on Debuff_Ticked, standing in for Comorbidity: extenders are only
	# queried for Skill_Resolved, so Black Thread must not reach it.
	cascade.SubscribeCascadeContributor(func(_p_event: CascadeEvent) -> CascadeContribution:
		if(Types.Cascade_Trigger.Debuff_Ticked != _p_event.trigger):
			return null
		return CascadeContribution.new(&"TestStatusBase", 1, CascadeContribution.Kind.Base,
				1.0, func(_e: CascadeEvent) -> void: run_count[0] += 1))

	resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Debuff_Ticked)
	event.subject_ID = 0
	cascade.Post(event)
	resolver._EndBatch()

	assert_eq(run_count[0], 1,
		"Black Thread must not add an instance to a cascade triggered off a status tick")

func test_non_black_thread_does_not_grant_extra_instances() -> void:
	var setup: Dictionary = _make_black_thread_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	herald_trait.AdvanceThread()  # back to Silver
	var resolver: BattleResolver = setup["resolver"]
	var cascade: CascadeResolver = resolver.GetCascadeResolver()
	var run_count: Array[int] = [0]
	_subscribe_test_base_contributor(cascade, run_count)

	resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 0
	event.target_IDs = [1]
	cascade.Post(event)
	resolver._EndBatch()

	assert_eq(run_count[0], 1)

# --- Cut the Cloth: Tension-driven repeats ---

func _make_cut_the_cloth_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Cut the Cloth"
	skill.target = Types.Skill_Target.Single_Enemy
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	skill.effects = [damage]
	return skill

func _make_cut_the_cloth_setup() -> Dictionary:
	var caster: Character = TestFactory.make_character()
	caster._rarity = Types.Rarity.Rare
	caster._current_health = caster._attributes[Types.Attribute.Health]
	var herald_trait: WeftAndWarpTrait = WeftAndWarpTrait.new()
	herald_trait.Init(Types.Rarity.Rare)
	caster._trait = herald_trait
	caster._skills = [_make_cut_the_cloth_skill()]
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	return {"trait": herald_trait, "resolver": resolver}

func _damage_results_against(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind and p_target_ID == r.target_ID)

func test_cut_the_cloth_resolves_once_at_zero_tension() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var resolver: BattleResolver = setup["resolver"]
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	assert_eq(_damage_results_against(results, 1).size(), 1,
		"Cut the Cloth should resolve exactly once at zero Tension (minimum once)")

func test_cut_the_cloth_resolves_once_per_tension_plus_the_base_cast() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = WeftAndWarpTrait.TENSION_MAX

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	assert_eq(_damage_results_against(results, 1).size(), 1 + WeftAndWarpTrait.TENSION_MAX,
		"Cut the Cloth should resolve once for the base cast plus once per Tension held")

func test_cut_the_cloth_consumes_all_tension() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = WeftAndWarpTrait.TENSION_MAX

	resolver.ResolveSkill(0, [1], 0)

	assert_eq(herald_trait._tension, 0)

func test_cut_the_clouth_repeats_do_not_feed_golden_thread() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait.AdvanceThread()  # Golden
	herald_trait._tension = WeftAndWarpTrait.TENSION_MAX

	resolver.ResolveSkill(0, [1], 0)

	assert_eq(herald_trait._tension, 0,
		"Cut the Cloth's own repeats must never re-fill Tension through Golden Thread")

func test_cut_the_cloth_base_hit_lands_before_any_burst_marker() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = 3

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var first_damage_index: int = -1
	var first_marker_index: int = -1
	for i in results.size():
		if(-1 == first_damage_index and CombatResult.Kind.Damage == results[i].kind
				and 1 == results[i].target_ID):
			first_damage_index = i
		if(-1 == first_marker_index and CombatResult.Kind.Cascade_Triggered == results[i].kind):
			first_marker_index = i
	assert_ne(first_damage_index, -1, "Cut the Cloth should still deal damage")
	assert_ne(first_marker_index, -1, "Tension repeats should each emit a burst marker")
	assert_lt(first_damage_index, first_marker_index,
		"The base cast's damage must land before any Tension repeat's burst marker")

func test_cut_the_cloth_emits_one_burst_marker_per_tension_repeat() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = WeftAndWarpTrait.TENSION_MAX

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var markers: Array[CombatResult] = results.filter(
			func(r: CombatResult) -> bool:
				return CombatResult.Kind.Cascade_Triggered == r.kind and "Cut the Cloth" == r.text)
	assert_eq(markers.size(), WeftAndWarpTrait.TENSION_MAX,
		"Exactly one burst marker per Tension repeat, none for the base cast")

func test_cut_the_cloth_burst_marker_immediately_precedes_its_repeat_damage() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = 3

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	for i in results.size():
		if(CombatResult.Kind.Cascade_Triggered != results[i].kind or "Cut the Cloth" != results[i].text):
			continue
		var next_target_result: CombatResult = null
		for j in range(i + 1, results.size()):
			if(1 == results[j].target_ID):
				next_target_result = results[j]
				break
		assert_not_null(next_target_result, "A burst marker must be followed by its instance's results")
		assert_eq(next_target_result.kind, CombatResult.Kind.Damage,
			"The result immediately after a Cut the Cloth burst marker must be that repeat's damage")

func test_cut_the_cloth_repeats_are_capped_by_the_shared_echo_budget() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = WeftAndWarpTrait.TENSION_MAX
	resolver._echoes_this_action = CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION - 3

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	assert_eq(_damage_results_against(results, 1).size(), 1 + 3,
		"Tension repeats must stop once the shared per-action Echo budget runs out, " +
		"leaving the base cast plus only the instances the remaining budget allowed")

func test_cut_the_cloth_combines_with_black_thread_and_borrowed_time() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = 3
	herald_trait.AdvanceThread()  # Golden
	herald_trait.AdvanceThread()  # Black
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Borrowed_Time
	buff.duration = 1
	buff.value = 0.4
	resolver.GetStatusResolver().ApplyBuff(0, buff)

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var markers: Array[CombatResult] = results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Cascade_Triggered == r.kind)
	assert_eq(markers.size(), 5,
		"3 Tension + Black Thread's extra Cut the Cloth Echo + Borrowed Time's own Echo = 5 markers")
	for marker in markers:
		assert_eq(marker.cascade_depth, 1, "Every contribution to this cast shares one cascade")

	var damage_results: Array[CombatResult] = _damage_results_against(results, 1)
	assert_eq(damage_results.size(), 6, "The base cast plus those 5 Echoes should each deal damage")
	for damage_result in damage_results.slice(1):
		assert_eq(damage_result.cascade_depth, 1, "Every Echo's damage shares the cast's cascade depth")

	var borrowed_time_echoes: Array[CombatResult] = damage_results.filter(
			func(r: CombatResult) -> bool: return r.combined_damage_modifier.Buckets().has(&"Cut the Cloth (repeat)"))
	assert_eq(borrowed_time_echoes.size(), 1,
		"Only Borrowed Time's own Echo carries a repeat bucket — Black Thread's Echo inherits " +
		"Cut the Cloth's dominant strength (1.0, no bucket) instead of Borrowed Time's fraction")
	assert_almost_eq(borrowed_time_echoes[0].combined_damage_modifier.Buckets()[&"Cut the Cloth (repeat)"],
		0.4 - 1.0, 0.0001, "Borrowed Time's Echo resolves at its own buff fraction, not the dominant Base's")

func test_max_tension_combined_with_black_thread_and_borrowed_time_still_respects_the_fan_out_cap() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = WeftAndWarpTrait.TENSION_MAX
	herald_trait.AdvanceThread()  # Golden
	herald_trait.AdvanceThread()  # Black
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Borrowed_Time
	buff.duration = 1
	buff.value = 0.4
	resolver.GetStatusResolver().ApplyBuff(0, buff)
	# 7 Tension + Black Thread's extra + Borrowed Time's own Echo request 9 instances, still
	# under MAX_CASCADE_INSTANCES_PER_ACTION on its own; consuming most of the shared budget
	# beforehand forces the cap to actually bind.
	resolver._echoes_this_action = CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION - 4

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	assert_eq(_damage_results_against(results, 1).size(), 1 + 4,
		"The base cast plus only the instances the remaining shared Echo budget allowed")

func test_self_bonus_applies_to_echo_damage_but_not_the_base_cast() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	herald_trait._tension = 1

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var damage_results: Array[CombatResult] = _damage_results_against(results, 1)

	assert_eq(damage_results.size(), 2, "One base cast plus one Echo from 1 Tension")
	assert_false(damage_results[0].combined_damage_modifier.Buckets().has(&"Weft and Warp"),
		"The self-bonus must not apply to the base cast, only to Echoes")
	assert_almost_eq(damage_results[1].combined_damage_modifier.Buckets().get(&"Weft and Warp", 0.0),
		WeftAndWarpTrait.SELF_BONUS_BY_RARITY[Types.Rarity.Rare], 0.0001,
		"The self-bonus should apply to the Echo, keyed under its own mechanic identity")

func test_cut_the_cloth_at_zero_tension_emits_no_burst_marker() -> void:
	var setup: Dictionary = _make_cut_the_cloth_setup()
	var resolver: BattleResolver = setup["resolver"]

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var markers: Array[CombatResult] = results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Cascade_Triggered == r.kind)
	assert_true(markers.is_empty(), "The minimum-once base cast alone must not emit a burst marker")

# --- Resolver-integration: Thread Snap / Pull the Thread ---

func _make_thread_snap_setup() -> Dictionary:
	var caster: Character = TestFactory.make_character()
	caster._rarity = Types.Rarity.Rare
	var herald_trait: WeftAndWarpTrait = WeftAndWarpTrait.new()
	herald_trait.Init(Types.Rarity.Rare)
	caster._trait = herald_trait
	var skill: Skill = Skill.new()
	skill.name = "Thread Snap"
	skill.target = Types.Skill_Target.Single_Enemy
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	var debuff: ApplyDebuffEffect = ApplyDebuffEffect.new()
	debuff.debuff_type = Types.Debuff_Type.Suppress
	debuff.duration = 1
	skill.effects = [debuff, damage]
	caster._skills = [skill]
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	return {"resolver": resolver, "enemy": enemy}

func test_thread_snap_applies_suppress_for_one_turn() -> void:
	var setup: Dictionary = _make_thread_snap_setup()
	var resolver: BattleResolver = setup["resolver"]
	var enemy: Character = setup["enemy"]
	resolver.ResolveSkill(0, [1], 0)
	var suppress: StatusEffects.Debuff = null
	for debuff in enemy._active_debuffs:
		if(Types.Debuff_Type.Suppress == debuff.type):
			suppress = debuff
	assert_not_null(suppress, "Thread Snap should apply Suppress")
	# The Herald starts on Silver Thread, which itself extends outgoing debuff duration by 1.
	assert_eq(suppress.duration, 2)

func test_pull_the_thread_applies_temporal_leak_and_bumps_turn_bar_backward() -> void:
	var caster: Character = TestFactory.make_character()
	caster._rarity = Types.Rarity.Rare
	var herald_trait: WeftAndWarpTrait = WeftAndWarpTrait.new()
	herald_trait.Init(Types.Rarity.Rare)
	caster._trait = herald_trait
	var skill: Skill = Skill.new()
	skill.name = "Pull the Thread"
	skill.target = Types.Skill_Target.Single_Enemy
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	var turn_bar: TurnBarEffect = TurnBarEffect.new()
	turn_bar.fraction = -0.15
	var debuff: ApplyDebuffEffect = ApplyDebuffEffect.new()
	debuff.debuff_type = Types.Debuff_Type.Temporal_Leak
	debuff.duration = 3
	skill.effects = [damage, turn_bar, debuff]
	caster._skills = [skill]
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var leak: StatusEffects.Debuff = null
	for debuff_on_target in enemy._active_debuffs:
		if(Types.Debuff_Type.Temporal_Leak == debuff_on_target.type):
			leak = debuff_on_target
	assert_not_null(leak, "Pull the Thread should apply Temporal Leak")
	# The Herald starts on Silver Thread, which itself extends outgoing debuff duration by 1.
	assert_eq(leak.duration, 4)
	assert_eq(herald_trait._tension, WeftAndWarpTrait.PULL_THE_THREAD_TENSION)

	var bump: CombatResult = null
	for result in results:
		if(CombatResult.Kind.Turn_Bar_Bump == result.kind and 1 == result.target_ID):
			bump = result
	assert_not_null(bump, "Pull the Thread should bump the target's turn bar")
	assert_lt(bump.fraction, 0.0, "Pull the Thread should push the target backward on the turn bar")
