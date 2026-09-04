class_name EquipmentPresetRegistry extends Node

## Preload-based lookup from a stable identifier string (matching the .tres base file
## name, e.g. "Red_Boots") to its EquipmentPreset, mirroring ReagentRegistry
## (DirAccess-based discovery is unsafe on Android export).

const PRESETS: Dictionary[String, EquipmentPreset] = {
	"Red_Boots": preload("res://Data/Item_Presets/Red_Boots.tres"),
	"Shield_Basic": preload("res://Data/Item_Presets/Shield_Basic.tres"),
	"Weapon_Basic_Spear": preload("res://Data/Item_Presets/Weapon_Basic_Spear.tres"),
}

const RELIC_PRESETS: Dictionary[String, EquipmentPreset] = {
	"The_Long_Furrow": preload("res://Data/Item_Presets/Relics/The_Long_Furrow.tres"),
	"Remnant_Fed_Edge": preload("res://Data/Item_Presets/Relics/Remnant_Fed_Edge.tres"),
	"Threefold_Bite": preload("res://Data/Item_Presets/Relics/Threefold_Bite.tres"),
	"The_Closed_Wound": preload("res://Data/Item_Presets/Relics/The_Closed_Wound.tres"),
	"The_Planted_Heel": preload("res://Data/Item_Presets/Relics/The_Planted_Heel.tres"),
	"Lantern_of_the_Standing_Ward": preload("res://Data/Item_Presets/Relics/Lantern_of_the_Standing_Ward.tres"),
	"The_Answering_Boss": preload("res://Data/Item_Presets/Relics/The_Answering_Boss.tres"),
	"The_Sealed_Docket": preload("res://Data/Item_Presets/Relics/The_Sealed_Docket.tres"),
	"The_Unguarded_Glass": preload("res://Data/Item_Presets/Relics/The_Unguarded_Glass.tres"),
	"The_Ossuary_Ledger": preload("res://Data/Item_Presets/Relics/The_Ossuary_Ledger.tres"),
	"The_Frayed_Hour": preload("res://Data/Item_Presets/Relics/The_Frayed_Hour.tres"),
	"Kiln_Brand": preload("res://Data/Item_Presets/Relics/Kiln_Brand.tres"),
	"Sunderplate_Nail": preload("res://Data/Item_Presets/Relics/Sunderplate_Nail.tres"),
	"The_Even_Tread": preload("res://Data/Item_Presets/Relics/The_Even_Tread.tres"),
	"Prism_of_Small_Favors": preload("res://Data/Item_Presets/Relics/Prism_of_Small_Favors.tres"),
	"Signatorys_Seal": preload("res://Data/Item_Presets/Relics/Signatorys_Seal.tres"),
	"The_Solvent_Mark": preload("res://Data/Item_Presets/Relics/The_Solvent_Mark.tres"),
	"Quorum_Bell": preload("res://Data/Item_Presets/Relics/Quorum_Bell.tres"),
	"Ceded_Ground": preload("res://Data/Item_Presets/Relics/Ceded_Ground.tres"),
	"The_Quiet_Mass": preload("res://Data/Item_Presets/Relics/The_Quiet_Mass.tres"),
	"Mercy_Stitch": preload("res://Data/Item_Presets/Relics/Mercy_Stitch.tres"),
	"The_Long_Second": preload("res://Data/Item_Presets/Relics/The_Long_Second.tres"),
	"Understudys_Coat": preload("res://Data/Item_Presets/Relics/Understudys_Coat.tres"),
	"Laden_Coffer": preload("res://Data/Item_Presets/Relics/Laden_Coffer.tres"),
}

static func Get(p_id: String) -> EquipmentPreset:
	return PRESETS.get(p_id)

static func GetRandomKey() -> String:
	var preset_keys: Array[String] = PRESETS.keys()
	return preset_keys[randi_range(0, preset_keys.size() - 1)]

static func GetRelic(p_id: String) -> EquipmentPreset:
	return RELIC_PRESETS.get(p_id)

static func GetRandomRelicKey() -> String:
	var relic_keys: Array[String] = RELIC_PRESETS.keys()
	return relic_keys[randi_range(0, relic_keys.size() - 1)]

static func GetRandomRelicKeyForSlot(p_slot: Types.Slot) -> String:
	var matching_keys: Array[String] = []
	for key in RELIC_PRESETS.keys():
		if(p_slot == RELIC_PRESETS[key]._slot):
			matching_keys.append(key)
	if(matching_keys.is_empty()):
		return ""
	return matching_keys[randi_range(0, matching_keys.size() - 1)]
