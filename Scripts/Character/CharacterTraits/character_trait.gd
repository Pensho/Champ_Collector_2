class_name CharacterTrait extends Resource

@warning_ignore_start("unused_private_class_variable")
var _execution_steps: Dictionary[Types.Combat_Event, Callable]
var _trait_texture: Texture2D
var _title: String = "Title"
var _body: String = "Body"
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

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_characters: Dictionary[int, Character],
		_p_character_repr: Array[CharacterRepresentation],
		_p_skill_name: String,
		_p_battle_ui: BattleUI,
		_p_caster_attributes: Dictionary[Types.Attribute, int]) -> TraitSkillResult:
	print("character_trait base class SkillCast() called!")
	return null

func OnDefend(
		_p_defender_ID: int,
		_p_defender_attributes: Dictionary[Types.Attribute, int],
		_p_characters: Dictionary[int, Character]) -> void:
	print("character_trait base class OnDefend() called!")

func OnDamageTaken(_p_character_repr: CharacterRepresentation, _p_rarity: Types.Rarity, _p_battle_ui: BattleUI) -> float:
	print("character_trait base class DamageTaken() called!")
	return 1.0

func OnDeath(p_character_repr: CharacterRepresentation) -> void:
	print("character_trait base class OnDeath() called!")

func GetTargetingDefenceMultiplier() -> float:
	return 1.0
