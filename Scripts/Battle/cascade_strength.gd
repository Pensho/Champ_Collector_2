class_name CascadeStrength extends RefCounted

## A scalar returned by a callback registered with CascadeResolver.SubscribeStrengthModifier
## (Concept_Document.md 1.1.3/1.1.4): mechanic_key groups it with any other Echo-strength
## contribution sharing that key, multiplier is the scalar itself. Null means the modifier
## does not apply to this event.

var mechanic_key: StringName
var multiplier: float = 1.0


func _init(p_mechanic_key: StringName, p_multiplier: float = 1.0) -> void:
	mechanic_key = p_mechanic_key
	multiplier = p_multiplier
