class_name CharacterTrait extends Resource


@warning_ignore_start("unused_private_class_variable")
var _execution_steps: Dictionary[Types.Combat_Event, Callable]
var _trait_texture: Texture2D
var _title: String = "Title"
var _body: String = "Body"
var _owner_rarity: Types.Rarity = Types.Rarity.Common
@warning_ignore_restore("unused_private_class_variable")

func Init(p_rarity: Types.Rarity) -> void:
	_owner_rarity = p_rarity

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	print("character_trait base class StartOfBattle() called!")

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

func StartOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	print("character_trait base class StartOfTurn() called!")

func EndOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	print("character_trait base class EndOfTurn() called!")

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	print("character_trait base class SkillCast() called!")
	return null

func OnDefend(
		_p_defender_ID: int,
		_p_defender_attributes: Dictionary[Types.Attribute, int],
		_p_characters: Dictionary[int, Character]) -> void:
	print("character_trait base class OnDefend() called!")

## Returns the multiplier applied to incoming damage (1.0 = unchanged, 0.0 = avoided).
func OnDamageTaken(_p_owner_ID: int, _p_resolver: BattleResolver) -> float:
	print("character_trait base class DamageTaken() called!")
	return 1.0

func OnDeath() -> void:
	print("character_trait base class OnDeath() called!")

func GetTargetingDefenceMultiplier() -> float:
	return 1.0

func OnReagentConsumed(
		_p_consumer_ID: int, _p_reagent: ReagentData, _p_resolver: BattleResolver) -> float:
	print("character_trait base class OnReagentConsumed() called!")
	return 0.0

func OnCriticalHit(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> void:
	print("character_trait base class OnCriticalHit() called!")

func OnAllyDeath(_p_owner_ID: int, _p_dead_ally_ID: int, _p_resolver: BattleResolver) -> void:
	print("character_trait base class OnAllyDeath() called!")

## Returns the fraction of an ally's incoming attack damage this owner redirects to
## itself (0.0 = no redirect).
func OnAllyDamageTaken(
		_p_owner_ID: int, _p_damaged_ally_ID: int, _p_resolver: BattleResolver) -> float:
	return 0.0
