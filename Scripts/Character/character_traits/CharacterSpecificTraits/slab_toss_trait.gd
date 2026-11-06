class_name SlabTossTrait extends CharacterTrait

## A Slab Tosser's slab (Encounter_Design_Document.md 2.2, Slab Tossers): each Slab Toss flips the
## slab on a chance roll that Hexed and Luck bias. The good side lands the hit with one more Echo;
## the bad side weakens the hit and Hexes the tosser.

const TOSS_SKILL_NAME: String = "Slab Toss"
const GOOD_SIDE_SCENE: PackedScene = preload(
		"res://Scenes/Battle_Visual_Effects/Hue_Eater_Visual_Effects/slab_toss_good.tscn")
const BAD_SIDE_SCENE: PackedScene = preload(
		"res://Scenes/Battle_Visual_Effects/Hue_Eater_Visual_Effects/slab_toss_bad.tscn")
const _CASCADE_MECHANIC_KEY: StringName = &"SlabToss"

@export var _good_side_chance: float = 0.0
@export var _bad_side_damage_multiplier: float = 0.0
@export var _bad_side_hexed_turns: int = 0

var _echo_armed: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_effect_archetypes = [GOOD_SIDE_SCENE, BAD_SIDE_SCENE]
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

func ResetForBattle() -> void:
	_echo_armed = false

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	p_resolver.GetCascadeResolver().SubscribeCascadeContributor(
			func(p_event: CascadeEvent) -> CascadeContribution:
				if(p_event.subject_ID != p_owner_ID or not _echo_armed):
					return null
				_echo_armed = false
				return CascadeContribution.new(_CASCADE_MECHANIC_KEY, 1),
			Types.Cascade_Trigger.Skill_Resolved)

func OnSkillCast(
		p_owner_ID: int,
		p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	_echo_armed = false
	var result: TraitSkillResult = TraitSkillResult.new()
	if(TOSS_SKILL_NAME != p_skill_name):
		return result
	var good_side: bool = p_resolver.RollFavoring(p_owner_ID, 0.0, 1.0, false) < _good_side_chance
	var target_ID: int = p_target_IDs[0] if not p_target_IDs.is_empty() else p_owner_ID
	p_resolver.EmitTraitEffect(p_owner_ID, target_ID, GOOD_SIDE_SCENE if good_side else BAD_SIDE_SCENE)
	if(good_side):
		_echo_armed = true
		return result
	result._damage_multiplier = _bad_side_damage_multiplier
	var hexed: StatusEffects.Debuff = StatusEffects.Debuff.new()
	hexed.type = Types.Debuff_Type.Hexed
	hexed.duration = _bad_side_hexed_turns
	hexed.source_ID = p_owner_ID
	p_resolver.GetStatusResolver().ApplyDebuff(p_owner_ID, hexed)
	return result
