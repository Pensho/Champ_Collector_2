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
	# Stamped onto this debuff when it was cast by a Comorbidity-carrying caster: its own
	# tick damage multiplies by the holder's total distinct debuff-type count (any source),
	# uncapped, recomputed fresh at every tick.
	var repeats_per_distinct_debuff: bool = false
	# Rider reduction on top of this debuff's own effect (the Scholar's Field of Study):
	# -weakness_reduction fraction off weakness_attribute, applied wherever this debuff's
	# own attribute snapshot is taken.
	var has_weakness_rider: bool = false
	var weakness_attribute: Types.Attribute = Types.Attribute.Health
	var weakness_reduction: float = 0.0
