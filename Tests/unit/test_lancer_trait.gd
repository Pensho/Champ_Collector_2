extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _trait: LancerTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null
var _fake_positions: TestFactory.FakeTurnPositions = null

func before_each() -> void:
	_character = Character.new()
	_character._current_health = 10
	_trait = LancerTrait.new()
	_characters = {0: _character, 1: Character.new()}
	_characters[1]._current_health = 10
	_fake_positions = TestFactory.FakeTurnPositions.new()
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]), _fake_positions)

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

func _attrs() -> Dictionary[Types.Attribute, int]:
	return {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}

func _bumps_for(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump and r.target_ID == p_target_ID)

# --- Turn-bar section span ---

func test_span_is_one_when_owner_and_target_share_a_section() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 2, 1: 2}
	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	assert_eq(_trait._charge_span, 1, "Same section should be a span of 1")

func test_span_is_five_at_opposite_ends_of_the_bar() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 0, 1: 4}
	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	assert_eq(_trait._charge_span, 5, "Opposite ends of a 5-section bar should be a span of 5")

func test_unknown_owner_section_yields_zero_span() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {1: 2}  # owner (0) reads -1
	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	assert_eq(_trait._charge_span, 0, "An unknown owner section must decline, not assume a span")

func test_unknown_target_section_yields_zero_span() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 2}  # target (1) reads -1
	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	assert_eq(_trait._charge_span, 0, "An unknown target section must decline, not assume a span")

func test_a_different_skill_clears_the_span() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 0, 1: 4}
	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	assert_eq(_trait._charge_span, 5)

	_trait.OnSkillCast(0, [1], "Lance Thrust", _attrs(), _resolver)
	assert_eq(_trait._charge_span, 0, "Casting a different skill should clear the cached span")

# --- GetConditionCount ---

func test_condition_count_scales_with_span_and_rarity() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.09,
		Types.Rarity.Rare: 0.12,
		Types.Rarity.Epic: 0.15,
		Types.Rarity.Legendary: 0.18,
	}
	for rarity in expected.keys():
		_InitTrait(rarity)
		_fake_positions.sections_by_character = {0: 0, 1: 2}  # span 3
		_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)

		var count: float = _trait.GetConditionCount(0, 1, Types.Trait_Count_Source.Turn_Bar_Section_Span, _resolver)

		assert_almost_eq(count, 3.0 * expected[rarity], 0.0001, "Rarity %s" % rarity)

func test_condition_count_is_zero_for_every_other_source() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fake_positions.sections_by_character = {0: 0, 1: 4}
	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)

	for source in Types.Trait_Count_Source.values():
		if(Types.Trait_Count_Source.Turn_Bar_Section_Span == source):
			continue
		assert_eq(_trait.GetConditionCount(0, 1, source, _resolver), 0.0, "Source %s" % source)

func test_condition_count_is_zero_with_no_charge_cast() -> void:
	_InitTrait(Types.Rarity.Legendary)
	assert_eq(_trait.GetConditionCount(0, 1, Types.Trait_Count_Source.Turn_Bar_Section_Span, _resolver), 0.0)

# --- Recoil on OnSkillEffectsResolved ---

func test_rending_charge_throws_the_lancer_back_half_the_span() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 0, 1: 2}  # span 3
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	_trait.OnSkillEffectsResolved(0, [1], "Rending Charge", _attrs(), _resolver)

	var bumps: Array[CombatResult] = _bumps_for(received, 0)
	assert_eq(bumps.size(), 1, "The Lancer should be bumped back exactly once")
	assert_almost_eq(bumps[0].fraction, -0.30, 0.0001, "3 sections * 10% recoil per section")

func test_no_recoil_with_zero_span() -> void:
	_InitTrait(Types.Rarity.Epic)
	# sections_by_character left empty: span resolves to 0
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	_trait.OnSkillEffectsResolved(0, [1], "Rending Charge", _attrs(), _resolver)

	assert_eq(_bumps_for(received, 0).size(), 0, "A zero span should throw no recoil")

func test_no_recoil_for_a_different_skill() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 0, 1: 2}
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	_trait.OnSkillCast(0, [1], "Lance Thrust", _attrs(), _resolver)
	_trait.OnSkillEffectsResolved(0, [1], "Lance Thrust", _attrs(), _resolver)

	assert_eq(_bumps_for(received, 0).size(), 0, "Only Rending Charge should throw recoil")

func test_recoil_reads_the_span_cached_at_cast_not_at_resolution() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 0, 1: 2}  # span 3 at cast
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	_fake_positions.sections_by_character = {0: 0, 1: 4}  # the bar moved before effects resolved
	_trait.OnSkillEffectsResolved(0, [1], "Rending Charge", _attrs(), _resolver)

	var bumps: Array[CombatResult] = _bumps_for(received, 0)
	assert_almost_eq(bumps[0].fraction, -0.30, 0.0001, "Recoil must use the span read at cast, not resolution")

func test_steadfast_on_the_lancer_suppresses_recoil() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fake_positions.sections_by_character = {0: 0, 1: 2}
	var steadfast: StatusEffects.Buff = StatusEffects.Buff.new()
	steadfast.type = Types.Buff_Type.Steadfast
	steadfast.duration = 2
	_character._active_buffs.append(steadfast)
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	_trait.OnSkillCast(0, [1], "Rending Charge", _attrs(), _resolver)
	_trait.OnSkillEffectsResolved(0, [1], "Rending Charge", _attrs(), _resolver)

	assert_eq(_bumps_for(received, 0).size(), 0, "Steadfast should block the Lancer's own recoil")
