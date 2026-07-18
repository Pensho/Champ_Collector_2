class_name StatueWeaponTrait extends CharacterTrait

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle() -> void:
	pass

func RefreshVisuals(_p_character_repr: CharacterRepresentation) -> void:
	pass
