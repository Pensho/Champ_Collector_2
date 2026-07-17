class_name CharacterTrait extends Resource

## Base class for champion traits. The combat hooks below are logic-only: they mutate
## trait/Character state and report effects through the BattleResolver they receive
## (ApplyBuff, EmitTraitText, GetRandom, ...), never through UI types. RefreshVisuals
## is the one view hook — the battle scene calls it to repaint trait icons, tooltips,
## and battlefield effects from the trait's current state.

@warning_ignore_start("unused_private_class_variable")
var _execution_steps: Dictionary[Types.Combat_Event, Callable]
var _trait_texture: Texture2D
var _title: String = "Title"
var _body: String = "Body"
@warning_ignore_restore("unused_private_class_variable")

func Init() -> void:
	print("character_trait base class Init() called!")

## Logic reset at the start of a battle (stack counters and the like).
func StartOfBattle() -> void:
	print("character_trait base class StartOfBattle() called!")

## View hook: repaint this trait's icons, tooltips, and visual effects on the
## owner's representation from current trait state.
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
func OnDamageTaken(_p_owner_ID: int, _p_rarity: Types.Rarity, _p_resolver: BattleResolver) -> float:
	print("character_trait base class DamageTaken() called!")
	return 1.0

func OnDeath() -> void:
	print("character_trait base class OnDeath() called!")

func GetTargetingDefenceMultiplier() -> float:
	return 1.0
