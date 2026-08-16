extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _trait: TimeTitheTrait = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_trait = TimeTitheTrait.new()
	_roster[3]._trait = _trait
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

func _push_skill(p_turn_effect: float) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Push"
	skill.target = Types.Skill_Target.Single_Enemy
	var effect: TurnBarEffect = TurnBarEffect.new()
	effect.fraction = p_turn_effect
	skill.effects = [effect]
	return skill

func _bumps_for(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump and r.target_ID == p_target_ID)

# --- Hook unit test ---

func test_hook_returns_the_rarity_scaled_tithe_fraction() -> void:
	_InitTrait(Types.Rarity.Epic)  # 45% tithe

	var tithe: float = _trait.OnEnemyTurnBarReduced(3, 0.20, _resolver)

	assert_almost_eq(tithe, 0.20 * 0.45, 0.0001, "Epic should tithe 45% of the stolen amount")

func test_hook_emits_trait_text_feedback() -> void:
	_InitTrait(Types.Rarity.Rare)
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	_trait.OnEnemyTurnBarReduced(3, 0.20, _resolver)

	var texts: Array[CombatResult] = received.filter(func(r): return r.kind == CombatResult.Kind.Trait_Text)
	assert_eq(texts.size(), 1, "A nonzero tithe should report trait text exactly once")
	assert_eq(texts[0].target_ID, 3)

# --- Seam integration: a holder's skill reducing an enemy's turn bar tithes back ---

func test_a_reducing_skill_tithes_turn_bar_back_to_the_caster() -> void:
	_InitTrait(Types.Rarity.Rare)  # 35% tithe
	_roster[3]._skills.append(_push_skill(-0.20))

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	var enemy_bumps: Array[CombatResult] = _bumps_for(results, 0)
	assert_eq(enemy_bumps.size(), 1, "The enemy should be pushed back once")
	assert_almost_eq(enemy_bumps[0].fraction, -0.20, 0.0001)

	var caster_bumps: Array[CombatResult] = _bumps_for(results, 3)
	assert_eq(caster_bumps.size(), 1, "The holder should be tithed once")
	assert_almost_eq(caster_bumps[0].fraction, 0.20 * 0.35, 0.0001, "Rare should tithe 35% of the stolen amount")

# --- Negative guards ---

func test_no_tithe_when_the_reduced_target_is_an_ally() -> void:
	_InitTrait(Types.Rarity.Rare)
	var ally_push: Skill = Skill.new()
	ally_push.name = "Ally Push"
	ally_push.target = Types.Skill_Target.Single_Ally
	var effect: TurnBarEffect = TurnBarEffect.new()
	effect.fraction = -0.20
	ally_push.effects = [effect]
	_roster[3]._skills.append(ally_push)

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [4], 0)

	assert_eq(_bumps_for(results, 3).size(), 0, "Reducing an ally's turn bar must not tithe the holder")

func test_no_tithe_on_a_positive_turn_bar_bump() -> void:
	_InitTrait(Types.Rarity.Rare)
	_roster[3]._skills.append(_push_skill(0.20))

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_bumps_for(results, 3).size(), 0, "Advancing an enemy's turn bar must not tithe the holder")

func test_no_tithe_without_a_source_so_the_owners_own_tithe_bump_cannot_recurse() -> void:
	# _EmitTurnBarBump's tithe application recurses with no source_ID (defaults to -1),
	# which must short-circuit here rather than re-triggering another tithe.
	var tithe: float = Skills.TurnBarTithe(-1, 3, -0.20, _roster, TestFactory.make_full_sides(), _resolver)

	assert_eq(tithe, 0.0, "A bump with no source must never tithe")

# --- Borrowed Time: the ally-forward grant half ---

func _make_fake_resolver(p_sections: Dictionary[int, int]) -> BattleResolver:
	var fake_positions := TestFactory.FakeTurnPositions.new()
	fake_positions.sections_by_character = p_sections
	return TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), fake_positions)

func _has_borrowed_time(p_character: Character) -> bool:
	for buff in p_character._active_buffs:
		if(Types.Buff_Type.Borrowed_Time == buff.type):
			return true
	return false

func test_grants_borrowed_time_when_the_boosted_ally_is_alone_in_its_section() -> void:
	_InitTrait(Types.Rarity.Legendary)  # 60% Borrowed Time
	_resolver = _make_fake_resolver({4: 2})  # owner (3) and the other ally (5) read -1

	_trait.OnAllyTurnBarIncreased(3, 4, 0.15, _resolver)

	assert_true(_has_borrowed_time(_roster[4]), "The lone ally should gain Borrowed Time")
	for buff in _roster[4]._active_buffs:
		if(Types.Buff_Type.Borrowed_Time == buff.type):
			assert_almost_eq(buff.value, 0.60, 0.0001, "Legendary should grant 60% strength")

func test_no_grant_when_another_ally_shares_the_targets_section() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_resolver = _make_fake_resolver({4: 2, 5: 2})

	_trait.OnAllyTurnBarIncreased(3, 4, 0.15, _resolver)

	assert_false(_has_borrowed_time(_roster[4]), "A shared section with another ally should deny the grant")

func test_no_grant_when_the_holder_itself_shares_the_targets_section() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_resolver = _make_fake_resolver({3: 2, 4: 2})

	_trait.OnAllyTurnBarIncreased(3, 4, 0.15, _resolver)

	assert_false(_has_borrowed_time(_roster[4]),
			"The holder counts as an occupant of its own section, per the design's alone-clause")

func test_no_grant_when_the_targets_section_is_unknown() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_resolver = _make_fake_resolver({})  # every query reads -1

	_trait.OnAllyTurnBarIncreased(3, 4, 0.15, _resolver)

	assert_false(_has_borrowed_time(_roster[4]), "An unknown section must decline to grant, not assume aloneness")

func test_borrowed_time_fraction_scales_by_rarity() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.30,
		Types.Rarity.Rare: 0.40,
		Types.Rarity.Epic: 0.50,
		Types.Rarity.Legendary: 0.60,
	}
	for rarity in expected.keys():
		_InitTrait(rarity)
		_resolver = _make_fake_resolver({4: 2})

		_trait.OnAllyTurnBarIncreased(3, 4, 0.15, _resolver)

		for buff in _roster[4]._active_buffs:
			if(Types.Buff_Type.Borrowed_Time == buff.type):
				assert_almost_eq(buff.value, expected[rarity], 0.0001, "Rarity %s" % rarity)
		_roster[4]._active_buffs.clear()

# --- Seam integration: a holder's skill that bumps an ally forward can grant it ---

func _ally_push_skill(p_turn_effect: float) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Ally Push"
	skill.target = Types.Skill_Target.Single_Ally
	var effect: TurnBarEffect = TurnBarEffect.new()
	effect.fraction = p_turn_effect
	skill.effects = [effect]
	return skill

func test_an_ally_forward_bump_grants_borrowed_time_when_alone_in_its_section() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_roster[3]._skills.append(_ally_push_skill(0.15))
	_resolver = _make_fake_resolver({4: 2})

	_resolver.ResolveSkill(3, [4], 0)

	assert_true(_has_borrowed_time(_roster[4]), "Flicker-Zone-style ally bump should grant Borrowed Time")

func test_no_grant_on_a_negative_ally_bump() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_roster[3]._skills.append(_ally_push_skill(-0.15))
	_resolver = _make_fake_resolver({4: 2})

	_resolver.ResolveSkill(3, [4], 0)

	assert_false(_has_borrowed_time(_roster[4]), "A backward bump must never grant Borrowed Time")

func test_no_grant_on_a_self_bump() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var self_push: Skill = Skill.new()
	self_push.name = "Self Push"
	self_push.target = Types.Skill_Target.Single_Ally
	var effect: TurnBarEffect = TurnBarEffect.new()
	effect.fraction = 0.15
	self_push.effects = [effect]
	_roster[3]._skills.append(self_push)
	_resolver = _make_fake_resolver({3: 2})

	_resolver.ResolveSkill(3, [3], 0)

	assert_false(_has_borrowed_time(_roster[3]), "A self-bump must never grant Borrowed Time")

func test_no_grant_on_an_enemy_forward_bump() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var enemy_push: Skill = Skill.new()
	enemy_push.name = "Enemy Push"
	enemy_push.target = Types.Skill_Target.Single_Enemy
	var effect: TurnBarEffect = TurnBarEffect.new()
	effect.fraction = 0.15
	enemy_push.effects = [effect]
	_roster[3]._skills.append(enemy_push)
	_resolver = _make_fake_resolver({0: 2})

	_resolver.ResolveSkill(3, [0], 0)

	assert_false(_has_borrowed_time(_roster[0]), "Pushing an enemy forward must never grant Borrowed Time")
