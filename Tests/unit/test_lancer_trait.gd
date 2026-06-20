extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")
const BATTLE_UI_SCRIPT = preload("res://Scripts/UI/Battle_UI/battle_ui.gd")

var _character: Character = null
var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null
var _repr: CharacterRepresentation = null
var _battle_ui: BattleUI = null
var _trait: LancerTrait = null
var _characters: Dictionary[int, Character]
var _repr_array: Array[CharacterRepresentation]

func before_each() -> void:
	_character = load("res://Scenes/Characters/Character.tscn").instantiate()
	_item_col = ItemCollection.new()
	_main_inst = Main_Instance.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst
	_repr = double(REPR_SCRIPT).new()
	stub(_repr, "AddStatusEffect").to_return(0)
	_battle_ui = double(BATTLE_UI_SCRIPT).new()
	_trait = LancerTrait.new()
	_trait.Init()
	_characters = {0: _character}
	_repr_array = []
	_repr_array.resize(1)
	_repr_array[0] = _repr

func after_each() -> void:
	_character.free()
	_repr.free()
	_battle_ui.free()
	_item_col.free()
	_main_inst.free()
	main._instance = null

# --- Rarity tables ---

func test_momentum_per_stack_uncommon() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Uncommon, 0.0), 0.04)

func test_momentum_per_stack_rare() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Rare, 0.0), 0.06)

func test_momentum_per_stack_epic() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Epic, 0.0), 0.08)

func test_momentum_per_stack_legendary() -> void:
	assert_eq(LancerTrait.MOMENTUM_PER_STACK.get(Types.Rarity.Legendary, 0.0), 0.10)

func test_radiance_defense_uncommon() -> void:
	assert_eq(LancerTrait.RADIANCE_DEFENSE.get(Types.Rarity.Uncommon, 0.0), 0.04)

func test_radiance_defense_legendary() -> void:
	assert_eq(LancerTrait.RADIANCE_DEFENSE.get(Types.Rarity.Legendary, 0.0), 0.10)

# --- Momentum stack accumulation ---

func test_offensive_skill_increments_momentum() -> void:
	_character._rarity = Types.Rarity.Epic
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, attributes)
	assert_eq(_trait._momentum_stacks, 1, "Offensive skill should add one Momentum stack")

func test_momentum_capped_at_max() -> void:
	_character._rarity = Types.Rarity.Epic
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	for i in LancerTrait.MAX_MOMENTUM_STACKS + 3:
		_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, attributes)
	assert_eq(_trait._momentum_stacks, LancerTrait.MAX_MOMENTUM_STACKS,
		"Momentum stacks must not exceed MAX_MOMENTUM_STACKS")

func test_unknown_skill_does_not_change_stacks() -> void:
	_character._rarity = Types.Rarity.Epic
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Fireball", _battle_ui, attributes)
	assert_eq(_trait._momentum_stacks, 0, "Unknown skill should leave stacks unchanged")

# --- Attack bonus from OnSkillCast ---

func test_attack_bonus_scales_with_stacks_and_rarity() -> void:
	_character._rarity = Types.Rarity.Epic  # 8% per stack
	# Build up 2 stacks with zero attack so no bonus is applied during stack accumulation.
	var stack_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, stack_attr)
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, stack_attr)
	assert_eq(_trait._momentum_stacks, 2)

	# Cast again with real attack value — stacks increment to 3 first, then bonus applies.
	var measure_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, measure_attr)
	# 3 stacks × 8% of 100 = ceil(24) = 24
	assert_eq(measure_attr[Types.Attribute.Attack], 124,
		"Attack should be boosted by 3 stacks × 8% = 24")

func test_first_cast_gains_stack_and_applies_bonus() -> void:
	_character._rarity = Types.Rarity.Legendary  # 10% per stack
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 80, Types.Attribute.Defence: 60}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, attributes)
	# Stack increments to 1, then bonus = ceil(80 × 10% × 1) = 8
	assert_eq(attributes[Types.Attribute.Attack], 88,
		"First offensive cast should increment to 1 stack and apply the bonus")

# --- OnDefend defence penalty ---

func test_defend_lowers_defence_proportional_to_stacks() -> void:
	_character._rarity = Types.Rarity.Epic  # 8% per stack → penalty 4% per stack
	var stack_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, stack_attr)
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Stab", _battle_ui, stack_attr)
	assert_eq(_trait._momentum_stacks, 2)

	var defend_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Defence: 100}
	_trait.OnDefend(0, defend_attr, _characters)
	# 2 stacks × (8%/2) of 100 = ceil(8) = 8 penalty
	assert_eq(defend_attr[Types.Attribute.Defence], 92,
		"Defence should drop by 2 stacks × 4% = 8")

func test_defend_no_penalty_with_zero_stacks() -> void:
	_character._rarity = Types.Rarity.Legendary
	var defend_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Defence: 100}
	_trait.OnDefend(0, defend_attr, _characters)
	assert_eq(defend_attr[Types.Attribute.Defence], 100,
		"Zero stacks should produce no defence penalty")

# --- Radiance buff on defensive skill ---

func test_defensive_skill_applies_radiance_buff() -> void:
	_character._rarity = Types.Rarity.Uncommon  # 4% Radiance
	_trait.defensive_skill_names["Shield_Bash"] = true
	_trait._momentum_stacks = 3

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Shield_Bash", _battle_ui, attributes)

	assert_eq(_character._active_buffs.size(), 1, "Radiance buff should be applied")
	assert_eq(_character._active_buffs[0].type, Types.Buff_Type.Radiance)
	assert_eq(_character._active_buffs[0].duration, 2)
	assert_almost_eq(_character._active_buffs[0].value, 0.04, 0.0001)

func test_defensive_skill_clears_all_momentum_stacks() -> void:
	_character._rarity = Types.Rarity.Rare
	_trait.defensive_skill_names["Shield_Bash"] = true
	_trait._momentum_stacks = 4

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Shield_Bash", _battle_ui, attributes)

	assert_eq(_trait._momentum_stacks, 0, "Defensive skill should consume all Momentum stacks")

func test_defensive_skill_with_zero_stacks_skips_radiance() -> void:
	_character._rarity = Types.Rarity.Rare
	_trait.defensive_skill_names["Shield_Bash"] = true
	# _momentum_stacks stays at 0

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 0, Types.Attribute.Defence: 0}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Shield_Bash", _battle_ui, attributes)

	assert_eq(_character._active_buffs.size(), 0, "No Radiance should be applied when stacks are zero")
