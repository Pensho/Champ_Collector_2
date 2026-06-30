extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")
const BATTLE_UI_SCRIPT = preload("res://Scripts/UI/Battle_UI/battle_ui.gd")
const TURN_BAR_SCRIPT = preload("res://Scripts/UI/Battle_UI/turn_bar.gd")

var _owner: Character = null
var _ally: Character = null
var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null
var _owner_repr: CharacterRepresentation = null
var _ally_repr: CharacterRepresentation = null
var _battle_ui: BattleUI = null
var _trait: PlanTrait = null
var _characters: Dictionary[int, Character]
var _repr_array: Array[CharacterRepresentation]
var _one_ally_behind: Array[int]
var _no_allies_behind: Array[int]

func before_each() -> void:
	_owner = Character.new()
	_ally = Character.new()
	_item_col = ItemCollection.new()
	_main_inst = Main_Instance.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst
	_owner_repr = double(REPR_SCRIPT).new()
	_ally_repr = double(REPR_SCRIPT).new()
	stub(_owner_repr, "AddStatusEffect").to_return(0)
	stub(_ally_repr, "AddStatusEffect").to_return(1)
	_battle_ui = double(BATTLE_UI_SCRIPT).new()
	_battle_ui._turn_bar = double(TURN_BAR_SCRIPT).new()
	_trait = PlanTrait.new()
	_trait.Init()
	_characters = {0: _owner, 1: _ally}
	_repr_array = []
	_repr_array.resize(2)
	_repr_array[0] = _owner_repr
	_repr_array[1] = _ally_repr
	_one_ally_behind = [1]
	_no_allies_behind = []

func after_each() -> void:
	_owner_repr.free()
	_ally_repr.free()
	_battle_ui._turn_bar.free()
	_battle_ui.free()
	_item_col.free()
	_main_inst.free()
	main._instance = null

# --- Rarity tables ---

func test_percent_behind_threshold_uncommon() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Uncommon, 0.0), 0.10)

func test_percent_behind_threshold_rare() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Rare, 0.0), 0.15)

func test_percent_behind_threshold_epic() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Epic, 0.0), 0.20)

func test_percent_behind_threshold_legendary() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Legendary, 0.0), 0.25)

# --- The Tactician itself is never buffed ---

func test_owner_is_never_empowered() -> void:
	_owner._rarity = Types.Rarity.Legendary
	stub(_battle_ui._turn_bar, "GetCharactersBehindBy").to_return(_one_ally_behind)

	_trait.StartOfTurn(0, _battle_ui, _characters, _repr_array)

	assert_eq(_owner._active_buffs.size(), 0, "Tactician should not buff itself")

# --- Allies within threshold are buffed at every rarity ---

func test_ally_within_threshold_is_empowered_at_low_rarity() -> void:
	_owner._rarity = Types.Rarity.Uncommon
	stub(_battle_ui._turn_bar, "GetCharactersBehindBy").to_return(_one_ally_behind)

	_trait.StartOfTurn(0, _battle_ui, _characters, _repr_array)

	assert_eq(_ally._active_buffs.size(), 1, "Ally within threshold should be empowered at any rarity")
	assert_eq(_ally._active_buffs[0].type, Types.Buff_Type.Empower)

func test_ally_within_threshold_is_empowered_at_high_rarity() -> void:
	_owner._rarity = Types.Rarity.Legendary
	stub(_battle_ui._turn_bar, "GetCharactersBehindBy").to_return(_one_ally_behind)

	_trait.StartOfTurn(0, _battle_ui, _characters, _repr_array)

	assert_eq(_ally._active_buffs.size(), 1, "Ally within threshold should be empowered at Legendary rarity")

func test_no_buff_when_no_allies_within_threshold() -> void:
	_owner._rarity = Types.Rarity.Legendary
	stub(_battle_ui._turn_bar, "GetCharactersBehindBy").to_return(_no_allies_behind)

	_trait.StartOfTurn(0, _battle_ui, _characters, _repr_array)

	assert_eq(_ally._active_buffs.size(), 0,
		"No ally buff should be applied when none qualify as within threshold")

func test_threshold_passed_to_turn_bar_matches_rarity() -> void:
	_owner._rarity = Types.Rarity.Epic
	var turn_bar: Object = _battle_ui._turn_bar
	stub(turn_bar, "GetCharactersBehindBy").to_return(_no_allies_behind)

	_trait.StartOfTurn(0, _battle_ui, _characters, _repr_array)

	assert_call_count(turn_bar, "GetCharactersBehindBy", 1)
	var call_params: Array = get_call_parameters(turn_bar, "GetCharactersBehindBy", 0)
	assert_eq(call_params, [0, 0.20], "Epic rarity should query the turn bar with a 20% threshold")
