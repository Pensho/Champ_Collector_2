class_name HueEaterTrait extends GatheredLightTrait

## The Hue-Eater's Translucent, her Gathered Light hexagon, and her luck line
## (Encounter_Design_Document.md 2.2). Kept through the phase 2 transition, so the hexagon carries
## over.

const LUCK_LINE: String = "All colour and chance falls to me."
const LUCK_LINE_COLOR: Color = Color(0.85, 0.85, 0.85)
const VISUALS_SCENE: PackedScene = preload(
		"res://Scenes/Battle_Visual_Effects/Hue_Eater_Visual_Effects/hue_eater_visuals.tscn")
const LAUNCH_SCENE: PackedScene = preload(
		"res://Scenes/Battle_Visual_Effects/Hue_Eater_Visual_Effects/gathered_light_launch.tscn")

@export var _translucent_health_loss_multiplier: float = 0.0
## Prismatic Rains cast in a row without Hexed on her before she speaks the luck line.
@export var _rains_before_luck_line: int = 0

var _casting_beams: bool = false
var _rains_without_hexed: int = 0
var _luck_line_spoken: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.End_Turn] = Callable(self, "EndOfTurn")
	_execution_steps[Types.Combat_Event.Ally_Attack_Landed] = Callable(self, "OnAllyAttackLanded")

func ResetForBattle() -> void:
	super.ResetForBattle()
	_casting_beams = false
	_rains_without_hexed = 0
	_luck_line_spoken = false

func GetIncomingHealthLossMultiplier(p_owner_ID: int, p_resolver: BattleResolver) -> float:
	if(_HoldsHexed(p_resolver.GetCharacters().get(p_owner_ID))):
		return 1.0
	return _translucent_health_loss_multiplier

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
	if(_casting_beams):
		_rains_without_hexed = 0 if _HoldsHexed(owner) else _rains_without_hexed + 1
	return TraitSkillResult.new()

func EndOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_casting_beams = false
	if(not _luck_line_spoken and _rains_without_hexed >= _rains_before_luck_line):
		_luck_line_spoken = true
		p_resolver.EmitTraitText(p_owner_ID, LUCK_LINE, LUCK_LINE_COLOR)

func OnAllyAttackLanded(
		p_owner_ID: int, p_attacker_ID: int, p_target_ID: int, p_resolver: BattleResolver) -> void:
	if(p_attacker_ID != p_owner_ID or not _casting_beams
			or not p_resolver.GetSides().AreEnemies(p_owner_ID, p_target_ID)):
		return
	var owner: Character = p_resolver.GetCharacters().get(p_owner_ID)
	if(null != owner and owner._in_phase_two):
		_parts = mini(_parts + 1, _parts_to_complete)

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var visual_effects: CharacterVisualEffects = p_character_repr.GetVisualEffects()
	var hexed: bool = _HoldsHexed(_Owner())
	visual_effects.SetTranslucent(not hexed)
	var visuals: HueEaterVisuals = visual_effects.TraitVisuals(VISUALS_SCENE)
	visuals.Show(visual_effects, _parts, hexed, _OwnerAlive())

func _LaunchScene() -> PackedScene:
	return LAUNCH_SCENE

func _HoldsHexed(p_character: Character) -> bool:
	return null != p_character and p_character._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Hexed == debuff.type)
