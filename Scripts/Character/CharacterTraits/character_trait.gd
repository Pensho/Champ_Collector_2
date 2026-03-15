class_name CharacterTrait extends Resource

var _character_repr: CharacterRepresentation

var _execution_steps: Dictionary[Types.Combat_Event, Callable]

func Init(p_character_repr: CharacterRepresentation) -> void:
	_character_repr = p_character_repr
	print("character_trait base class Init() called!")

func StartOfBattle() -> void:
	print("character_trait base class StartOfBattle() called!")

func StartOfTurn() -> void:
	print("character_trait base class StartOfTurn() called!")

func EndOfTurn() -> void:
	print("character_trait base class EndOfTurn() called!")

func OnSkillCast(p_skill_name: String) -> TraitSkillResult:
	print("character_trait base class SkillCast() called!")
	return null

func OnDamageTaken() -> void:
	print("character_trait base class DamageTaken() called!")

func OnDeath() -> void:
	print("character_trait base class OnDeath() called!")
