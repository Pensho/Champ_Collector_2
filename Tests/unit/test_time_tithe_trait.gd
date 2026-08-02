extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _trait: ChronophageTrait = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_trait = ChronophageTrait.new()
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

# --- Rarity table ---

func test_tithe_fraction_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.25,
		Types.Rarity.Rare: 0.35,
		Types.Rarity.Epic: 0.45,
		Types.Rarity.Legendary: 0.55,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(ChronophageTrait.TITHE_FRACTION.get(rarity, 0.0), expected[rarity],
			"TITHE_FRACTION at %s" % Types.RarityName(rarity))

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

# --- Seam integration: a Chronophage skill reducing an enemy's turn bar tithes back ---

func test_a_reducing_skill_tithes_turn_bar_back_to_the_caster() -> void:
	_InitTrait(Types.Rarity.Rare)  # 35% tithe
	_roster[3]._skills.append(_push_skill(-0.20))

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	var enemy_bumps: Array[CombatResult] = _bumps_for(results, 0)
	assert_eq(enemy_bumps.size(), 1, "The enemy should be pushed back once")
	assert_almost_eq(enemy_bumps[0].fraction, -0.20, 0.0001)

	var caster_bumps: Array[CombatResult] = _bumps_for(results, 3)
	assert_eq(caster_bumps.size(), 1, "The Chronophage should be tithed once")
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

	assert_eq(_bumps_for(results, 3).size(), 0, "Reducing an ally's turn bar must not tithe the Chronophage")

func test_no_tithe_on_a_positive_turn_bar_bump() -> void:
	_InitTrait(Types.Rarity.Rare)
	_roster[3]._skills.append(_push_skill(0.20))

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_bumps_for(results, 3).size(), 0, "Advancing an enemy's turn bar must not tithe the Chronophage")

func test_no_tithe_without_a_source_so_the_owners_own_tithe_bump_cannot_recurse() -> void:
	# _EmitTurnBarBump's tithe application recurses with no source_ID (defaults to -1),
	# which must short-circuit here rather than re-triggering another tithe.
	var tithe: float = Skills.TurnBarTithe(-1, 3, -0.20, _roster, TestFactory.make_full_sides(), _resolver)

	assert_eq(tithe, 0.0, "A bump with no source must never tithe")
