class_name CharacterTrait extends Resource

var _execution_steps: Dictionary[Types.Combat_Event, Callable]

func Init() -> void:
	print("character_trait base class Init() called!")

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class StartOfBattle() called!")

func StartOfTurn(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class StartOfTurn() called!")

func EndOfTurn(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class EndOfTurn() called!")

func OnSkillCast(p_skill_name: String, p_character_repr: CharacterRepresentation) -> TraitSkillResult:
	print("character_trait base class SkillCast() called!")
	return null

func OnDamageTaken(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class DamageTaken() called!")

func OnDeath(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class OnDeath() called!")
