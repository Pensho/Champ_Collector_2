extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")

var _character: Character = null
var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null
var _repr: CharacterRepresentation = null

func before_each() -> void:
	_character = load("res://Scenes/Characters/Character.tscn").instantiate()
	_item_col = ItemCollection.new()
	_main_inst = Main_Instance.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst
	_repr = double(REPR_SCRIPT).new()

func after_each() -> void:
	_character.free()
	_repr.free()
	_item_col.free()
	_main_inst.free()
	main._instance = null

# --- STEAL_CHANCE table ---

func test_steal_chance_uncommon() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Uncommon, 0.0), 0.20,
		"Uncommon Thief should have 20% steal chance")

func test_steal_chance_rare() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Rare, 0.0), 0.30,
		"Rare Thief should have 30% steal chance")

func test_steal_chance_epic() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Epic, 0.0), 0.40,
		"Epic Thief should have 40% steal chance")

func test_steal_chance_legendary() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Legendary, 0.0), 0.50,
		"Legendary Thief should have 50% steal chance")

func test_steal_chance_common_is_zero() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Common, 0.0), 0.0,
		"Common rarity should default to 0% steal chance")

func test_steal_chance_relic_is_zero() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Relic, 0.0), 0.0,
		"Relic rarity should default to 0% steal chance")

# --- Skills.RemoveBuff ---

func test_remove_buff_erases_from_active_buffs() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 2
	buff.ID = 0
	_character._active_buffs.append(buff)

	assert_eq(_character._active_buffs.size(), 1, "Buff should be present before removal")

	# RemoveBuff does not use the battle_ui param, so null is safe here.
	Skills.RemoveBuff(_character, buff, _repr, null)

	assert_eq(_character._active_buffs.size(), 0, "Buff should be erased after RemoveBuff")

func test_remove_buff_only_erases_target_buff() -> void:
	var buff_a: StatusEffects.Buff = StatusEffects.Buff.new()
	buff_a.type = Types.Buff_Type.Empower
	buff_a.duration = 2
	buff_a.ID = 0

	var buff_b: StatusEffects.Buff = StatusEffects.Buff.new()
	buff_b.type = Types.Buff_Type.Fortify
	buff_b.duration = 3
	buff_b.ID = 1

	_character._active_buffs.append(buff_a)
	_character._active_buffs.append(buff_b)

	Skills.RemoveBuff(_character, buff_a, _repr, null)

	assert_eq(_character._active_buffs.size(), 1, "Only the targeted buff should be removed")
	assert_eq(_character._active_buffs[0].type, Types.Buff_Type.Fortify,
		"Remaining buff should be the one that was not removed")
