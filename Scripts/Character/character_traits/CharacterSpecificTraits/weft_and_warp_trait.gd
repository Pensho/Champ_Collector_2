class_name WeftAndWarpTrait extends CharacterTrait

## The owner holds exactly one thread, freely switchable during its
## own turn (a UI-driven free action, not modeled here) and otherwise persistent trait state.

enum Thread_Type
{
	Silver,
	Golden,
	Black,
}

const TENSION_MAX: int = 7
const PULL_THE_THREAD_TENSION: int = 2

const SELF_BONUS_BY_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.10,
	Types.Rarity.Rare: 0.13,
	Types.Rarity.Epic: 0.16,
	Types.Rarity.Legendary: 0.19,
}

const STARTING_TENSION_BY_RARITY: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Uncommon: 0,
	Types.Rarity.Rare: 0,
	Types.Rarity.Epic: 1,
	Types.Rarity.Legendary: 1,
}

var _current_thread: Thread_Type = Thread_Type.Silver
var _tension: int = 0
var _self_bonus: float = 0.0
var _pending_cut_the_cloth_instances: int = 0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_self_bonus = SELF_BONUS_BY_RARITY.get(p_rarity, 0.0)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Weft_And_Warp_Trait/weft_and_warp_trait.png")
	_title = "Weft and Warp"
	_body = ("Always holds one thread, freely switchable during its own turn.\n" +
			"Golden: gain 1 Tension when an Echo resolves on an enemy.\n" +
			"Silver: The owner's debuffs cannot be resisted and last 1 turn longer.\n" +
			"Black: the Echo this owner's action produces resolves one " +
			"additional time. Echoes the owner produces deal +%d%% damage." %
			roundi(100.0 * _self_bonus))
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Cascade_Instance_Resolved] = Callable(self, "OnCascadeInstanceResolved")
	_execution_steps[Types.Combat_Event.Skill_Effects_Resolved] = Callable(self, "OnSkillEffectsResolved")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_current_thread = Thread_Type.Silver
	_tension = STARTING_TENSION_BY_RARITY.get(_owner_rarity, 0)
	# Re-subscribed every battle: p_resolver (and its CascadeResolver) is fresh per combat.
	p_resolver.GetCascadeResolver().SubscribeInstanceModifier(
			func(p_event: CascadeEvent, _p_mechanic_key: StringName) -> int:
				if(Thread_Type.Black != _current_thread):
					return 0
				if(_EventCasterID(p_event) != p_owner_ID):
					return 0
				if(not _EventConcernsEnemyOf(p_owner_ID, p_event, p_resolver)):
					return 0
				return 1)

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_state: String = (_body + "\n\n" +
			"Current Thread: " + Thread_Type.keys()[_current_thread] + "\n" +
			"Current Tension: " + str(_tension))
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_state, 0)

func GetCurrentThread() -> Thread_Type:
	return _current_thread

func AdvanceThread() -> void:
	match _current_thread:
		Thread_Type.Silver:
			_current_thread = Thread_Type.Golden
		Thread_Type.Golden:
			_current_thread = Thread_Type.Black
		Thread_Type.Black:
			_current_thread = Thread_Type.Silver

func GetOutgoingDebuffDurationBonus(_p_owner_ID: int) -> int:
	return 1 if Thread_Type.Silver == _current_thread else 0

func DebuffsCannotBeResisted(_p_owner_ID: int) -> bool:
	return Thread_Type.Silver == _current_thread

func OnCascadeInstanceResolved(
		p_owner_ID: int, p_event: CascadeEvent, p_resolver: BattleResolver) -> void:
	if(Thread_Type.Golden != _current_thread):
		return
	if(not _EventConcernsEnemyOf(p_owner_ID, p_event, p_resolver)):
		return
	_tension = mini(_tension + 1, TENSION_MAX)

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	match p_skill_name:
		"Pull the Thread":
			# Stance-independent: granted regardless of the currently active thread.
			_tension = mini(_tension + PULL_THE_THREAD_TENSION, TENSION_MAX)
		"Cut the Cloth":
			result._damage_multiplier = 1.0 + _self_bonus
			_pending_cut_the_cloth_instances = _tension
			_tension = 0
	return result

## Resolves the extra instances a Cut the Cloth cast banked in OnSkillCast, once
## BattleResolver.ResolveSkill's own effect loop for that cast has finished — so the
## burst reads base hit first, then repeats.
func OnSkillEffectsResolved(
		p_owner_ID: int,
		p_target_IDs: Array[int],
		p_skill_name: String,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> void:
	if("Cut the Cloth" != p_skill_name):
		return
	var extra_instances: int = _pending_cut_the_cloth_instances
	_pending_cut_the_cloth_instances = 0
	_ResolveExtraCutTheClothInstances(p_owner_ID, p_target_IDs, p_caster_attributes, extra_instances, p_resolver)

## Resolves Cut the Cloth's Tension-driven repeats as a local loop that never calls
## CascadeResolver.Post — deliberately so these repeats cannot feed this Herald's own
## Golden Thread (a self-feed loop), unlike a Skill_Resolved-based repeat mechanic.
## Each instance still emits a BattleResolver.EmitBurstInstance marker so the battle view
## escalates its combat text the same as a real cascade instance would.
func _ResolveExtraCutTheClothInstances(
		p_owner_ID: int,
		p_target_IDs: Array[int],
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_extra_instances: int,
		p_resolver: BattleResolver) -> void:
	if(p_extra_instances <= 0):
		return
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	if(not characters.has(p_owner_ID)):
		return
	var caster: Character = characters[p_owner_ID]
	var cast_skill: Skill = null
	for skill: Skill in caster._skills:
		if("Cut the Cloth" == skill.name):
			cast_skill = skill
			break
	if(null == cast_skill):
		return
	for i in p_extra_instances:
		p_resolver.EmitBurstInstance(&"Cut the Cloth", p_owner_ID, Types.Cascade_Trigger.Skill_Resolved)
		var trait_result := TraitSkillResult.new()
		trait_result._damage_multiplier = 1.0 + _self_bonus
		var context := SkillCastContext.new(
				p_resolver, p_owner_ID, p_target_IDs, cast_skill, p_caster_attributes, 0, trait_result)
		for effect in cast_skill.effects:
			if(effect is DamageEffect and context.ConditionMet(effect)):
				effect.Resolve(context)

func _EventCasterID(p_event: CascadeEvent) -> int:
	return p_event.origin_ID if -1 != p_event.origin_ID else p_event.subject_ID

func _EventConcernsEnemyOf(p_owner_ID: int, p_event: CascadeEvent, p_resolver: BattleResolver) -> bool:
	var sides: CombatSides = p_resolver.GetSides()
	if(not p_event.target_IDs.is_empty()):
		for target_ID: int in p_event.target_IDs:
			if(sides.AreEnemies(p_owner_ID, target_ID)):
				return true
		return false
	return sides.AreEnemies(p_owner_ID, p_event.subject_ID)
