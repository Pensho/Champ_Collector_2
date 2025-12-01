extends Node
class_name StatusEffects

const Types = preload("res://Scripts/common_enums.gd")

const BUFF_ICONS: Dictionary[Types.Buff_Type, String] = {
	Types.Buff_Type.Invalid: "N/A",
}

const DEBUFF_ICONS: Dictionary[Types.Debuff_Type, String] = {
	Types.Debuff_Type.Burning: "res://Assets/Champ Collector/Icons/Status_Effects/Burning/flame.svg",
}

class Buff:
	var effect: Types.Buff_Type = Types.Buff_Type.Invalid
	var duration: int = 0
	var ID: = 0

class Debuff:
	var effect: Types.Debuff_Type = Types.Debuff_Type.Invalid
	var duration: int = 0
	var ID: = 0
