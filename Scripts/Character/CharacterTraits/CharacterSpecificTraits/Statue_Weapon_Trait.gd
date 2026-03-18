class_name StatueWeaponTrait extends CharacterTrait

func Init() -> void:
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	pass
