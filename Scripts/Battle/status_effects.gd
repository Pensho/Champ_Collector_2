extends Node
class_name StatusEffects

const BUFF_ICONS: Dictionary[Types.Buff_Type, String] = {
	Types.Buff_Type.Invalid: "N/A",
}

const DEBUFF_ICONS: Dictionary[Types.Debuff_Type, String] = {
	Types.Debuff_Type.Burning: "res://Assets/Champ_Collector/Icons/Status_Effects/Burning/flame.svg",
	Types.Debuff_Type.Enfeeble: "res://Assets/Champ_Collector/Icons/Status_Effects/Enfeeble/shattered-sword.svg",
	Types.Debuff_Type.Expose_Weakness: "res://Assets/Champ_Collector/Icons/Status_Effects/Expose_weakness/broken-shield.svg",
}

class Effect:
	var duration: int = 0
	var ID: = 0
	var stackable: bool = true

class Buff extends Effect:
	var type: Types.Buff_Type = Types.Buff_Type.Invalid

class Debuff extends Effect:
	var type: Types.Debuff_Type = Types.Debuff_Type.Invalid
