extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _trait: LancerTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func before_each() -> void:
	_character = Character.new()
	_character._current_health = 10
	_trait = LancerTrait.new()
	_characters = {0: _character}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], []))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

# --- Rarity tables ---

func test_momentum_per_stack_uncommon() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Uncommon, 0.0), 0.04)

func test_momentum_per_stack_rare() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Rare, 0.0), 0.06)

func test_momentum_per_stack_epic() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Epic, 0.0), 0.08)

func test_momentum_per_stack_legendary() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Legendary, 0.0), 0.10)

func test_phalanx_guard_defense_uncommon() -> void:
	assert_eq(LancerTrait.PHALANX_GUARD_DEFENSE.get(Types.Rarity.Uncommon, 0.0), 0.04)

func test_phalanx_guard_defense_legendary() -> void:
	assert_eq(LancerTrait.PHALANX_GUARD_DEFENSE.get(Types.Rarity.Legendary, 0.0), 0.10)

# --- Momentum stack accumulation ---

func test_offensive_skill_increments_momentum() -> void:
	_InitTrait(Types.Rarity.Epic)
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}
	_trait.OnSkillCast(0, [], "Stab", attributes, _resolver)
	assert_eq(_trait._momentum_stacks, 1, "Offensive skill should add one Momentum stack")

func test_momentum_capped_at_max() -> void:
	_InitTrait(Types.Rarity.Epic)
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	for i in LancerTrait.MAX_MOMENTUM_STACKS + 3:
		_trait.OnSkillCast(0, [], "Stab", attributes, _resolver)
	assert_eq(_trait._momentum_stacks, LancerTrait.MAX_MOMENTUM_STACKS,
		"Momentum stacks must not exceed MAX_MOMENTUM_STACKS")

func test_unknown_skill_does_not_change_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)
	assert_eq(_trait._momentum_stacks, 0, "Unknown skill should leave stacks unchanged")

# --- Attack bonus from OnSkillCast ---

func test_attack_bonus_scales_with_stacks_and_rarity() -> void:
	_InitTrait(Types.Rarity.Epic)  # 8% per stack
	# Build up 2 stacks with zero attack so no bonus is applied during stack accumulation.
	var stack_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], "Stab", stack_attr, _resolver)
	_trait.OnSkillCast(0, [], "Stab", stack_attr, _resolver)
	assert_eq(_trait._momentum_stacks, 2)

	# Cast again with real attack value — stacks increment to 3 first, then bonus applies.
	var measure_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}
	_trait.OnSkillCast(0, [], "Stab", measure_attr, _resolver)
	# 3 stacks × 8% of 100 = ceil(24) = 24
	assert_eq(measure_attr[Types.Attribute.Attack], 124,
		"Attack should be boosted by 3 stacks × 8% = 24")

func test_first_cast_gains_stack_and_applies_bonus() -> void:
	_InitTrait(Types.Rarity.Legendary)  # 10% per stack
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 80, Types.Attribute.Defence: 60}
	_trait.OnSkillCast(0, [], "Stab", attributes, _resolver)
	# Stack increments to 1, then bonus = ceil(80 × 10% × 1) = 8
	assert_eq(attributes[Types.Attribute.Attack], 88,
		"First offensive cast should increment to 1 stack and apply the bonus")

# --- OnDefend defence penalty ---

func test_defend_lowers_defence_proportional_to_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)  # 8% per stack → penalty 4% per stack
	var stack_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], "Stab", stack_attr, _resolver)
	_trait.OnSkillCast(0, [], "Stab", stack_attr, _resolver)
	assert_eq(_trait._momentum_stacks, 2)

	var defend_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Defence: 100}
	_trait.OnDefend(0, defend_attr, _characters)
	# 2 stacks × (8%/2) of 100 = ceil(8) = 8 penalty
	assert_eq(defend_attr[Types.Attribute.Defence], 92,
		"Defence should drop by 2 stacks × 4% = 8")

func test_defend_no_penalty_with_zero_stacks() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var defend_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Defence: 100}
	_trait.OnDefend(0, defend_attr, _characters)
	assert_eq(defend_attr[Types.Attribute.Defence], 100,
		"Zero stacks should produce no defence penalty")

# --- Phalanx Guard buff on defensive skill ---

func test_defensive_skill_applies_phalanx_guard_buff() -> void:
	_InitTrait(Types.Rarity.Uncommon)  # 4% Phalanx Guard
	_trait.defensive_skill_names["Shield_Bash"] = true
	_trait._momentum_stacks = 3

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], "Shield_Bash", attributes, _resolver)

	assert_eq(_character._active_buffs.size(), 1, "Phalanx Guard buff should be applied")
	assert_eq(_character._active_buffs[0].type, Types.Buff_Type.Phalanx_Guard)
	assert_eq(_character._active_buffs[0].duration, 2)
	assert_almost_eq(_character._active_buffs[0].value, 0.04, 0.0001)

func test_defensive_skill_clears_all_momentum_stacks() -> void:
	_InitTrait(Types.Rarity.Rare)
	_trait.defensive_skill_names["Shield_Bash"] = true
	_trait._momentum_stacks = 4

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], "Shield_Bash", attributes, _resolver)

	assert_eq(_trait._momentum_stacks, 0, "Defensive skill should consume all Momentum stacks")

func test_defensive_skill_with_zero_stacks_skips_phalanx_guard() -> void:
	_InitTrait(Types.Rarity.Rare)
	_trait.defensive_skill_names["Shield_Bash"] = true
	# _momentum_stacks stays at 0

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], "Shield_Bash", attributes, _resolver)

	assert_eq(_character._active_buffs.size(), 0, "No Phalanx Guard should be applied when stacks are zero")
