class_name HueEaterTrait extends CharacterTrait

## The Hue-Eater's Translucent and Gathered Light (Encounter_Design_Document.md 2.2). Kept through
## the phase 2 transition, so the hexagon carries over.

const LAUNCH_TEXT: String = "Gathered Light"
const ENFEEBLE_TEXT: String = "Enfeeble"
const ENFEEBLE_TEXT_COLOR: Color = Color(0.75, 0.55, 1.0)
const VISUALS_SCENE: PackedScene = preload("res://Scenes/Battle_Visual_Effects/hue_eater_visuals.tscn")
const LAUNCH_SCENE: PackedScene = preload("res://Scenes/Battle_Visual_Effects/gathered_light_launch.tscn")

@export var _translucent_health_loss_multiplier: float = 0.25
@export var _slices_to_complete: int = 6
@export var _slices_per_enfeeble: int = 2
@export var _launch_damage_scaling: Dictionary[Types.Attribute, float] = {Types.Attribute.Mysticism: 1.5}

var _slices: int = 0
var _casting_beams: bool = false
var _owner: WeakRef = null

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_effect_archetypes = [LAUNCH_SCENE]
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.End_Turn] = Callable(self, "EndOfTurn")
	_execution_steps[Types.Combat_Event.Debuff_Received] = Callable(self, "OnDebuffReceived")
	_execution_steps[Types.Combat_Event.Ally_Attack_Landed] = Callable(self, "OnAllyAttackLanded")

	_title = "Hue-Eater"
	_body = "Translucent unless Hexed. Gathers light into a hexagon that Enfeeble breaks apart."

func ResetForBattle() -> void:
	_slices = 0
	_casting_beams = false

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_owner = weakref(p_resolver.GetCharacters().get(p_owner_ID))

func GetSlices() -> int:
	return _slices

func GetIncomingHealthLossMultiplier(p_owner_ID: int, p_resolver: BattleResolver) -> float:
	if(_HoldsHexed(p_resolver.GetCharacters().get(p_owner_ID))):
		return 1.0
	return _translucent_health_loss_multiplier

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	if(_slices < _slices_to_complete):
		_slices += 1
		return
	_slices = 0
	p_resolver.EmitTraitText(p_owner_ID, LAUNCH_TEXT)
	var party_IDs: Array[int] = p_resolver.GetSides().EnemiesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	if(not party_IDs.is_empty()):
		p_resolver.EmitTraitEffect(p_owner_ID, party_IDs[0], LAUNCH_SCENE)
	p_resolver.ResolveTraitDamage(p_owner_ID, party_IDs, p_resolver.GetEffectiveAttributes(p_owner_ID),
			_launch_damage_scaling, false)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	_casting_beams = false
	var owner: Character = p_resolver.GetCharacters().get(p_owner_ID)
	if(null != owner):
		for skill: Skill in owner._skills:
			if(skill.name == p_skill_name):
				_casting_beams = skill.effects.any(func(effect: SkillEffect) -> bool: return effect is PrismaticBeamEffect)
				break
	return TraitSkillResult.new()

func EndOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_casting_beams = false

func OnAllyAttackLanded(
		p_owner_ID: int, p_attacker_ID: int, p_target_ID: int, p_resolver: BattleResolver) -> void:
	if(p_attacker_ID != p_owner_ID or not _casting_beams
			or not p_resolver.GetSides().AreEnemies(p_owner_ID, p_target_ID)):
		return
	var owner: Character = p_resolver.GetCharacters().get(p_owner_ID)
	if(null != owner and owner._in_phase_two):
		_slices = mini(_slices + 1, _slices_to_complete)

func OnDebuffReceived(p_owner_ID: int, p_debuff: StatusEffects.Debuff, p_resolver: BattleResolver) -> void:
	if(Types.Debuff_Type.Enfeeble != p_debuff.type):
		return
	p_resolver.GetStatusResolver().RemoveDebuff(p_owner_ID, p_debuff)
	_slices = maxi(0, _slices - _slices_per_enfeeble)
	p_resolver.EmitTraitText(p_owner_ID, ENFEEBLE_TEXT, ENFEEBLE_TEXT_COLOR)

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var visual_effects: CharacterVisualEffects = p_character_repr.GetVisualEffects()
	var owner: Character = _owner.get_ref() if null != _owner else null
	var hexed: bool = _HoldsHexed(owner)
	visual_effects.SetTranslucent(not hexed)
	var visuals: HueEaterVisuals = visual_effects.TraitVisuals(VISUALS_SCENE)
	visuals.Show(visual_effects, _slices, hexed, null != owner and owner._current_health > 0)

func _HoldsHexed(p_character: Character) -> bool:
	return null != p_character and p_character._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Hexed == debuff.type)
