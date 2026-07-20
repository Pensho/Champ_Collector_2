class_name StatusEffects extends Node


class Effect:
	var duration: int = 0
	var ID: int = 0
	var stackable: bool = true
	var name: String = ""
	var value: float = 0.0
	# Character ID that applied this effect, or -1 when there is no combatant source
	# (e.g. adventure-map effects). Used to attribute damage-over-time back to its caster.
	var source_ID: int = -1

class Buff extends Effect:
	var type: Types.Buff_Type = Types.Buff_Type.Invalid

class Debuff extends Effect:
	var type: Types.Debuff_Type = Types.Debuff_Type.Invalid
	# Rarity-dependent bonus (e.g. the Plague Doctor's Comorbidity) stamped onto this
	# debuff when it was cast, scaling its own tick damage with the target's debuff count.
	var tick_bonus_per_debuff: float = 0.0
