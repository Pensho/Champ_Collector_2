class_name CharacterTrait extends Resource

enum Combat_Event
{
	Start_Combat,
	#Start_Turn,
	#End_Turn,
	#Skill_Cast,
	#Damage_Taken,
	#On_Death,
}

var _execution_steps: Dictionary[Combat_Event, Callable]

func Init() -> void:
	print("character_trait base class Init() called!")

func ConnectDrawSignal() -> void:
	pass

func StartOfBattle() -> void:
	print("character_trait base class StartOfBattle() called!")

#func StartOfTurn() -> void:
	#print("character_trait base class StartOfTurn() called!")
#
#func EndOfTurn() -> void:
	#print("character_trait base class EndOfTurn() called!")
#
#func SkillCast() -> void:
	#print("character_trait base class SkillCast() called!")
#
#func DamageTaken() -> void:
	#print("character_trait base class DamageTaken() called!")
#
#func OnDeath() -> void:
	#print("character_trait base class OnDeath() called!")
