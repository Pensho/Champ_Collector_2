class_name StatueWeaponTrait extends CharacterTrait

func Init() -> void:
	_execution_steps[Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	pass

func StartOfBattle() -> void:
	# Print graphics
	pass
