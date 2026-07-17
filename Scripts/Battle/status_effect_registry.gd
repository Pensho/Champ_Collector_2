class_name StatusEffectRegistry extends Node

## Preload-based lookup from buff/debuff type to its StatusEffectData, mirroring the
## preloaded-Dictionary precedent in Scripts/Debug/debug_catalog.gd (DirAccess-based
## discovery is unsafe on Android export).

const BUFFS: Dictionary[Types.Buff_Type, StatusEffectData] = {
	Types.Buff_Type.Empower: preload("res://Data/Status_Effects/Empower.tres"),
	Types.Buff_Type.Fortify: preload("res://Data/Status_Effects/Fortify.tres"),
	Types.Buff_Type.Daunting_Strength: preload("res://Data/Status_Effects/Daunting_Strength.tres"),
	Types.Buff_Type.Phalanx_Guard: preload("res://Data/Status_Effects/Phalanx_Guard.tres"),
}

const DEBUFFS: Dictionary[Types.Debuff_Type, StatusEffectData] = {
	Types.Debuff_Type.Burning: preload("res://Data/Status_Effects/Burning.tres"),
	Types.Debuff_Type.Enfeeble: preload("res://Data/Status_Effects/Enfeeble.tres"),
	Types.Debuff_Type.Expose_Weakness: preload("res://Data/Status_Effects/Expose_Weakness.tres"),
}

static func BuffData(p_type: Types.Buff_Type) -> StatusEffectData:
	return BUFFS.get(p_type)

static func DebuffData(p_type: Types.Debuff_Type) -> StatusEffectData:
	return DEBUFFS.get(p_type)
