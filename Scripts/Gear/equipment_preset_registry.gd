class_name EquipmentPresetRegistry extends Node

## Preload-based lookup from a stable identifier string (matching the .tres base file
## name, e.g. "Red_Boots") to its EquipmentPreset, mirroring ReagentRegistry
## (DirAccess-based discovery is unsafe on Android export).

const PRESETS: Dictionary[String, EquipmentPreset] = {
	"Red_Boots": preload("res://Data/Item_Presets/Red_Boots.tres"),
	"Shield_Basic": preload("res://Data/Item_Presets/Shield_Basic.tres"),
	"Weapon_Basic_Spear": preload("res://Data/Item_Presets/Weapon_Basic_Spear.tres"),
}

static func Get(p_id: String) -> EquipmentPreset:
	return PRESETS.get(p_id)

static func GetRandomKey() -> String:
	var preset_keys: Array[String] = PRESETS.keys()
	return preset_keys[randi_range(0, preset_keys.size() - 1)]
