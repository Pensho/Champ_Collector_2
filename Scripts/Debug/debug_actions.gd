class_name DebugActions extends Node

## The Relic presets whose effect script has real hook overrides rather than the title/
## body/magnitude-only stub every catalog entry starts as (Plan_Relic_Implementation.md
## Phase 4's batches 1 and 2). Kept as an explicit list rather than a "does it override
## anything" runtime check, since a stub is a valid, inspectable RelicEffect too.
const IMPLEMENTED_RELIC_KEYS: Array[String] = [
	"The_Quiet_Mass", "The_Planted_Heel", "The_Answering_Boss", "Kiln_Brand",
	"Sunderplate_Nail", "The_Ossuary_Ledger",
	"The_Even_Tread", "The_Frayed_Hour", "The_Solvent_Mark", "Signatorys_Seal",
	"Quorum_Bell", "Prism_of_Small_Favors",
]

## Adds one copy of every implemented Relic to the collection at the given rarity,
## following the same duplicate-set_rarity-Setup sequence LootManager and ShopHandler
## use when they roll a Relic drop.
static func grant_all_implemented_relics(p_item_collection: ItemCollection, p_rarity: Types.Rarity) -> void:
	for key in IMPLEMENTED_RELIC_KEYS:
		var preset: EquipmentPreset = EquipmentPresetRegistry.GetRelic(key).duplicate(true)
		preset._rarity = p_rarity
		preset.Setup()
		p_item_collection.AddPreset(preset)

## Builds an equipment preset with exact attribute values, bypassing the
## random rolls in EquipmentPreset.Setup(), so the debug item construction
## page can hand the collection an item with precisely chosen stats.
static func build_equipment_preset(
		p_name: String,
		p_slot: Types.Slot,
		p_rarity: Types.Rarity,
		p_attributes: Dictionary[Types.Attribute, int]) -> EquipmentPreset:
	var preset: EquipmentPreset = EquipmentPreset.new()
	preset._name = p_name
	preset._slot = p_slot
	preset._rarity = p_rarity
	preset._texture_path = DebugCatalog.GetItemTextureForSlot(p_slot)
	for attribute in p_attributes.keys():
		preset._attributes[attribute] = p_attributes[attribute]
	return preset

## Assembles a battle ContextContainer the same way Pre_Battle_Menu does, so
## launching a battle from the debug overlay follows the normal setup path.
static func build_battle_context(
		p_player_characters: Array[Character],
		p_battle_context: Context_Battle,
		p_difficulty: int,
		p_previous_scene: String,
		p_battle_reagents: Array[String] = []) -> ContextContainer:
	var context: ContextContainer = ContextContainer.new()
	context._scene = DebugCatalog.BATTLE_SCENE_UID
	context._static_context = p_battle_context
	context._player_battle_characters = p_player_characters
	context._battle_reagents = p_battle_reagents
	context._arguments["Difficulty"] = p_difficulty
	context._previous_scene = p_previous_scene
	return context

## Raises a character to the target level by repeatedly applying the real
## level-up reward (LevelSystem.LevelUpReward), the same procedure a battle-won
## experience gain triggers, so debug level-ups grant the same attribute growth.
## Lowering the level is a plain assignment: there's no inverse of a level-up.
static func set_character_level(p_character: Character, p_target_level: int) -> void:
	var clamped_target: int = clampi(p_target_level, 1, Game_Balance.MAX_LEVEL)
	if(clamped_target > p_character._level):
		while(p_character._level < clamped_target):
			LevelSystem.LevelUpReward(p_character)
	else:
		p_character._level = clamped_target
