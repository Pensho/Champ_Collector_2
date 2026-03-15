class_name StatueWeaponTrait extends CharacterTrait

func Init(p_character_repr: CharacterRepresentation) -> void:
	_character_repr = p_character_repr
	_execution_steps[Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle() -> void:
	pass
