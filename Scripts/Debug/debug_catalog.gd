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
	"Sorcerer": preload("res://Data/Character_Player_Variants/Sorcerer.tres"),
	"Symbiote": preload("res://Data/Character_Player_Variants/Symbiote.tres"),
	"Diviner": preload("res://Data/Character_Player_Variants/Diviner.tres"),
	"Appraiser": preload("res://Data/Character_Player_Variants/Appraiser.tres"),
	"Emissary": preload("res://Data/Character_Player_Variants/Emissary.tres"),
	"Cultist": preload("res://Data/Character_Player_Variants/Cultist.tres"),
	"Plague Doctor": preload("res://Data/Character_Player_Variants/Plague_Doctor.tres"),
	"Warlord": preload("res://Data/Character_Player_Variants/Warlord.tres"),
	"Alchemist": preload("res://Data/Character_Player_Variants/Alchemist.tres"),
}

const ENEMY_CHARACTER_PRESETS: Dictionary[String, CharacterPreset] = {
	"Militia": preload("res://Data/Character_Enemy_Variants/Militia.tres"),
	"Troll": preload("res://Data/Character_Enemy_Variants/Troll.tres"),
	"Obsidian Stallion": preload("res://Data/Character_Enemy_Variants/Obsidian_Stallion.tres"),
	"Statue Weapon": preload("res://Data/Character_Enemy_Variants/Statue_Weapon.tres"),
	"Statue Shield": preload("res://Data/Character_Enemy_Variants/Statue_Shield.tres"),
	"Statue Boots": preload("res://Data/Character_Enemy_Variants/Statue_Boots.tres"),
	"Spore Hound": preload("res://Data/Character_Enemy_Variants/Spore_Hound.tres"),
	"Sporeback Matron": preload("res://Data/Character_Enemy_Variants/Sporeback_Matron.tres"),
	"Skimmer Cutthroat": preload("res://Data/Character_Enemy_Variants/Skimmer_Cutthroat.tres"),
	"Bosun": preload("res://Data/Character_Enemy_Variants/Bosun.tres"),
	"Warded Clerk": preload("res://Data/Character_Enemy_Variants/Warded_Clerk.tres"),
	"Outrider Lancer": preload("res://Data/Character_Enemy_Variants/Outrider_Lancer.tres"),
	"War Drummer": preload("res://Data/Character_Enemy_Variants/War_Drummer.tres"),
	"Scavenger Skirmisher": preload("res://Data/Character_Enemy_Variants/Scavenger_Skirmisher.tres"),
	"Ridge Marksman": preload("res://Data/Character_Enemy_Variants/Ridge_Marksman.tres"),
	"Flank Cutter": preload("res://Data/Character_Enemy_Variants/Flank_Cutter.tres"),
	"Plains Charger": preload("res://Data/Character_Enemy_Variants/Plains_Charger.tres"),
	"Drover": preload("res://Data/Character_Enemy_Variants/Drover.tres"),
	"Cinder Husk": preload("res://Data/Character_Enemy_Variants/Cinder_Husk.tres"),
	"Ashen Oracle": preload("res://Data/Character_Enemy_Variants/Ashen_Oracle.tres"),
	"Glyphbound Archivist": preload("res://Data/Character_Enemy_Variants/Glyphbound_Archivist.tres"),
	"Collector of Debts": preload("res://Data/Character_Enemy_Variants/Collector_of_Debts.tres"),
	"Warded Notary": preload("res://Data/Character_Enemy_Variants/Warded_Notary.tres"),
	"Vault Warden": preload("res://Data/Character_Enemy_Variants/Vault_Warden.tres"),
	"Reliquary Core": preload("res://Data/Character_Enemy_Variants/Reliquary_Core.tres"),
}

## Pre-made enemy wave layouts the battle launcher debug page can pick from.
const BATTLE_CONTEXTS: Dictionary[String, Context_Battle] = {
	"Militia": preload("res://Data/Battle_Variants/Battle_Militia.tres"),
	"Troll": preload("res://Data/Battle_Variants/Battle_Troll.tres"),
	"Obsidian Stallion": preload("res://Data/Battle_Variants/Battle_Obsidian_Stallion.tres"),
	"Statue Weapon": preload("res://Data/Battle_Variants/Battle_Statue_Weapon.tres"),
	"Statue Shield": preload("res://Data/Battle_Variants/Battle_Statue_Shield.tres"),
	"Statue Boots": preload("res://Data/Battle_Variants/Battle_Statue_Boots.tres"),
	"Sporeback Pack": preload("res://Data/Battle_Variants/Battle_Sporeback_Pack.tres"),
	"Wake Skimmers": preload("res://Data/Battle_Variants/Battle_Wake_Skimmers.tres"),
	"Ledger Clerks": preload("res://Data/Battle_Variants/Battle_Ledger_Clerks.tres"),
	"Plains Outriders": preload("res://Data/Battle_Variants/Battle_Plains_Outriders.tres"),
	"Ridge Marksmen": preload("res://Data/Battle_Variants/Battle_Ridge_Marksmen.tres"),
	"Flank Cutter": preload("res://Data/Battle_Variants/Battle_Flank_Cutter.tres"),
	"Line Breaker": preload("res://Data/Battle_Variants/Battle_Line_Breaker.tres"),
	"Ashen Oracle": preload("res://Data/Battle_Variants/Battle_Ashen_Oracle.tres"),
	"Glyphbound Archivist": preload("res://Data/Battle_Variants/Battle_Glyphbound_Archivist.tres"),
	"Collector of Debts": preload("res://Data/Battle_Variants/Battle_Collector_of_Debts.tres"),
	"Warden of the Reliquary": preload("res://Data/Battle_Variants/Battle_Warden_of_the_Reliquary.tres"),
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
