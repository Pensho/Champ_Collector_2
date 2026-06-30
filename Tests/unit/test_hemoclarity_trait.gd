extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")
const BATTLE_UI_SCRIPT = preload("res://Scripts/UI/Battle_UI/battle_ui.gd")

var _character: Character = null
var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null
var _repr: CharacterRepresentation = null
var _battle_ui: BattleUI = null
var _trait: HemoclarityTrait = null
var _characters: Dictionary[int, Character]
var _repr_array: Array[CharacterRepresentation]

func before_each() -> void:
	_character = Character.new()
	_item_col = ItemCollection.new()
	_main_inst = Main_Instance.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst
	_repr = double(REPR_SCRIPT).new()
	_battle_ui = double(BATTLE_UI_SCRIPT).new()
	_trait = HemoclarityTrait.new()
	_trait.Init()
	_characters = {0: _character}
	_repr_array = []
	_repr_array.resize(1)
	_repr_array[0] = _repr

func after_each() -> void:
	_repr.free()
	_battle_ui.free()
	_item_col.free()
	_main_inst.free()
	main._instance = null

# --- MYSTICISM_BONUS table ---

func test_mysticism_bonus_uncommon() -> void:
	assert_eq(HemoclarityTrait.MYSTICISM_BONUS.get(Types.Rarity.Uncommon, 0.0), 0.25)

func test_mysticism_bonus_rare() -> void:
	assert_eq(HemoclarityTrait.MYSTICISM_BONUS.get(Types.Rarity.Rare, 0.0), 0.30)

func test_mysticism_bonus_epic() -> void:
	assert_eq(HemoclarityTrait.MYSTICISM_BONUS.get(Types.Rarity.Epic, 0.0), 0.35)

func test_mysticism_bonus_legendary() -> void:
	assert_eq(HemoclarityTrait.MYSTICISM_BONUS.get(Types.Rarity.Legendary, 0.0), 0.40)

# --- Health threshold behaviour ---

func test_below_half_health_increases_mysticism() -> void:
	_character._rarity = Types.Rarity.Epic
	_character._attributes[Types.Attribute.Health] = 100
	_character._currentHealth = 199 # below 50% of 100 * ATTRIBUTE_HEALTH_MULTIPLIER (4) = 400

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Fireball", _battle_ui, attributes)

	# Epic = 35% bonus, ceil(100 * 0.35) = 35
	assert_eq(attributes[Types.Attribute.Mysticism], 135,
		"Mysticism should be boosted by 35% while below half health")

func test_at_half_health_no_bonus() -> void:
	_character._rarity = Types.Rarity.Epic
	_character._attributes[Types.Attribute.Health] = 100
	_character._currentHealth = 200 # exactly 50% of max health (400)

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Fireball", _battle_ui, attributes)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"No bonus should apply at exactly half health")

func test_above_half_health_no_bonus() -> void:
	_character._rarity = Types.Rarity.Legendary
	_character._attributes[Types.Attribute.Health] = 100
	_character._currentHealth = 400 # full health

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Fireball", _battle_ui, attributes)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"No bonus should apply above half health")

func test_rarity_scaling_uncommon_vs_epic() -> void:
	_character._attributes[Types.Attribute.Health] = 100
	_character._currentHealth = 1 # near zero, below half

	var uncommon_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_character._rarity = Types.Rarity.Uncommon
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Fireball", _battle_ui, uncommon_attr)
	assert_eq(uncommon_attr[Types.Attribute.Mysticism], 125,
		"Uncommon should give +25% Mysticism")

	var epic_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_character._rarity = Types.Rarity.Epic
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Fireball", _battle_ui, epic_attr)
	assert_eq(epic_attr[Types.Attribute.Mysticism], 135,
		"Epic should give +35% Mysticism")

# --- Max health guard ---

func test_zero_max_health_does_not_divide_by_zero() -> void:
	_character._rarity = Types.Rarity.Legendary
	_character._attributes[Types.Attribute.Health] = 0
	_character._currentHealth = 0

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], _characters, _repr_array, "Fireball", _battle_ui, attributes)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"Zero max health should be guarded and apply no bonus")
