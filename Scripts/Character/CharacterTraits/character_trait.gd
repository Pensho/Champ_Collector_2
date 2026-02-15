class_name CharacterTrait extends Resource

enum Combat_Event
{
	Start_Combat,
	Start_Turn,
	End_Turn,
	Skill_Cast,
	Damage_Taken,
	On_Death,
}

var _execution_steps: Dictionary[Combat_Event, Callable]

func Init() -> void:
	print("character_trait base class Init() called!")

func ConnectDrawSignal() -> void:
	pass

func StartOfBattle() -> void:
	print("character_trait base class StartOfBattle() called!")
