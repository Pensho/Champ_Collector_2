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
	assert_true(_trait.DebuffsCannotBeResisted(0))
	_trait.AdvanceThread()  # Golden
	assert_false(_trait.DebuffsCannotBeResisted(0))

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

func test_black_thread_grants_one_extra_instance_to_the_herald_own_cascade() -> void:
	var setup: Dictionary = _make_black_thread_setup()
	var resolver: BattleResolver = setup["resolver"]
	var cascade: CascadeResolver = resolver.GetCascadeResolver()
	var run_count: Array[int] = [0]
	cascade.Subscribe(Types.Cascade_Trigger.Skill_Resolved, &"TestListener",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: run_count[0] += 1)

	resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 0
	event.target_IDs = [1]
	event.instance_count = 1
	cascade.Post(event)
	resolver._EndBatch()

	assert_eq(run_count[0], 2, "Black Thread should add one extra instance to the Herald's own cascade")

func test_black_thread_does_not_affect_another_characters_cascade() -> void:
	var setup: Dictionary = _make_black_thread_setup()
	var resolver: BattleResolver = setup["resolver"]
	var cascade: CascadeResolver = resolver.GetCascadeResolver()
	var run_count: Array[int] = [0]
	cascade.Subscribe(Types.Cascade_Trigger.Skill_Resolved, &"TestListener",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: run_count[0] += 1)

	resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 1  # not the Herald
	event.target_IDs = [0]
	event.instance_count = 1
	cascade.Post(event)
	resolver._EndBatch()

	assert_eq(run_count[0], 1, "Black Thread must not amplify a cascade it did not cause")

func test_non_black_thread_does_not_grant_extra_instances() -> void:
	var setup: Dictionary = _make_black_thread_setup()
	var herald_trait: WeftAndWarpTrait = setup["trait"]
	herald_trait.AdvanceThread()  # back to Silver
	var resolver: BattleResolver = setup["resolver"]
	var cascade: CascadeResolver = resolver.GetCascadeResolver()
	var run_count: Array[int] = [0]
	cascade.Subscribe(Types.Cascade_Trigger.Skill_Resolved, &"TestListener",
			func(_p_event: CascadeEvent) -> bool: return true,
			func(_p_event: CascadeEvent) -> void: run_count[0] += 1)

	resolver._BeginBatch()
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 0
	event.target_IDs = [1]
	event.instance_count = 1
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
