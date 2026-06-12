class_name DebugCatalog extends Node

## Scene UID for the battle scene, used by the battle launcher debug page.
const BATTLE_SCENE_UID: String = "uid://cc883blynrgq2"

## Scene UID returned to from the post-battle screen after a debug-launched battle.
const MAIN_MENU_SCENE_UID: String = "uid://c6c1o3oabj0pf"

const PLAYER_CHARACTER_PRESETS: Dictionary[String, CharacterPreset] = {
	"Knight": preload("res://Data/Character_Player_Variants/Knight.tres"),
	"Thief": preload("res://Data/Character_Player_Variants/Thief.tres"),
	"Bar Brawler": preload("res://Data/Character_Player_Variants/Bar_Brawler.tres"),
	"Jester": preload("res://Data/Character_Player_Variants/Jester.tres"),
	"Herald of the Loom": preload("res://Data/Character_Player_Variants/Herald_of_the_loom.tres"),
	"Bloodmage": preload("res://Data/Character_Player_Variants/Bloodmage.tres"),
	"Tidal Corsair": preload("res://Data/Character_Player_Variants/Tidal_Corsair.tres"),
	"Centaur Lancer": preload("res://Data/Character_Player_Variants/Centaur_Lancer.tres"),
	"Centaur Archivist": preload("res://Data/Character_Player_Variants/Centaur_Archivist.tres"),
	"Tactician": preload("res://Data/Character_Player_Variants/Tactician.tres"),
	"Architect": preload("res://Data/Character_Player_Variants/Architect.tres"),
	"Chronophage": preload("res://Data/Character_Player_Variants/Chronophage.tres"),
}

const ENEMY_CHARACTER_PRESETS: Dictionary[String, CharacterPreset] = {
	"Militia": preload("res://Data/Character_Enemy_Variants/Militia.tres"),
	"Troll": preload("res://Data/Character_Enemy_Variants/Troll.tres"),
	"Obsidian Stallion": preload("res://Data/Character_Enemy_Variants/Obsidian_Stallion.tres"),
	"Statue Weapon": preload("res://Data/Character_Enemy_Variants/Statue_Weapon.tres"),
	"Statue Shield": preload("res://Data/Character_Enemy_Variants/Statue_Shield.tres"),
	"Statue Boots": preload("res://Data/Character_Enemy_Variants/Statue_Boots.tres"),
}

## Pre-made enemy wave layouts the battle launcher debug page can pick from.
const BATTLE_CONTEXTS: Dictionary[String, Context_Battle] = {
	"Militia": preload("res://Data/Battle_Variants/Battle_Militia.tres"),
	"Troll": preload("res://Data/Battle_Variants/Battle_Troll.tres"),
	"Obsidian Stallion": preload("res://Data/Battle_Variants/Battle_Obsidian_Stallion.tres"),
	"Statue Weapon": preload("res://Data/Battle_Variants/Battle_Statue_Weapon.tres"),
	"Statue Shield": preload("res://Data/Battle_Variants/Battle_Statue_Shield.tres"),
}

## Used when constructing a debug item for a slot that has no dedicated icon.
const DEBUG_ITEM_TEXTURE_FALLBACK: String = "res://Assets/Champ_Collector/Icons/Items/Red_Boot/Red_Boot_0003.png"

## Known item icons per slot, used so constructed debug items have a real texture.
const ITEM_SLOT_TEXTURES: Dictionary[Types.Slot, String] = {
	Types.Slot.Weapon: "res://Assets/Champ_Collector/Icons/Items/Spear/Spear_0002.png",
	Types.Slot.Shield: "res://Assets/Champ_Collector/Icons/Items/Shield/Shield_0002.png",
	Types.Slot.Boots: "res://Assets/Champ_Collector/Icons/Items/Red_Boot/Red_Boot_0003.png",
}

static func GetItemTextureForSlot(p_slot: Types.Slot) -> String:
	if(ITEM_SLOT_TEXTURES.has(p_slot)):
		return ITEM_SLOT_TEXTURES[p_slot]
	return DEBUG_ITEM_TEXTURE_FALLBACK
