class_name CharacterTrait extends Resource

@warning_ignore_start("unused_private_class_variable")
var _execution_steps: Dictionary[Types.Combat_Event, Callable]
@warning_ignore_restore("unused_private_class_variable")

func Init() -> void:
	print("character_trait base class Init() called!")

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class StartOfBattle() called!")

func StartOfTurn(
		p_owner_ID: int,
		p_battle_UI: BattleUI,
		p_characters: Dictionary[int, Character],
		p_character_repr: Array[CharacterRepresentation]) -> void:
	print("character_trait base class StartOfTurn() called!")
	return

func EndOfTurn(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class EndOfTurn() called!")

func OnSkillCast(p_skill_name: String, p_character_repr: CharacterRepresentation) -> TraitSkillResult:
	print("character_trait base class SkillCast() called!")
	return null

func OnDamageTaken(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class DamageTaken() called!")

func OnDeath(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class OnDeath() called!")
