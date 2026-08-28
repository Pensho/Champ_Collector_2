class_name SorcererTrait extends CharacterTrait

const ECHO_COMPOUNDING: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 1.40,
	Types.Rarity.Rare: 1.50,
	Types.Rarity.Epic: 1.60,
	Types.Rarity.Legendary: 1.70,
}

const REAGENT_AMPLIFICATION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.20,
	Types.Rarity.Rare: 0.30,
	Types.Rarity.Epic: 0.40,
	Types.Rarity.Legendary: 0.50,
}

const MAX_INSTABILITY_STACKS: int = 5
const SURGE_MYSTICISM_SCALING: float = 1.4
const REPEAT_FRACTION: float = 0.5

# Flat, non-rarity-scaled per-Echo multiplier applied to a zone this cast placed,
# compounding across Echoes via repeated ZoneResolver.AmplifyZoneDamage calls.
const ECHO_ZONE_AMPLIFICATION: float = 1.15

# Cascade mechanic identity for the Skill_Resolved subscription (Concept_Document.md
# 1.1.3's composition-law currency) — a trait resource, not this Sorcerer's character
# identity, so two Sorcerers on the same team dedup independently by subject_ID.
const _CASCADE_MECHANIC_KEY: StringName = &"SorcererTrait"

var _instability_stacks: int = 0
var _echo_compounding: float = 1.0
var _reagent_amplification: float = 0.0
var _echo_charges: int = 0
var _echoes_for_this_cast: int = 0
# 0-based counter driving each Echo's own compounding fraction within one cast's repeat.
var _echo_index: int = 0
var _placed_zone_ID_this_cast: int = -1

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_echo_compounding = ECHO_COMPOUNDING.get(p_rarity, 1.0)
	_reagent_amplification = REAGENT_AMPLIFICATION.get(p_rarity, 0.0)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Arcane_Instability/arcane_instability_trait.png"
	)
	_title = "Arcane Instability"
	_body = ("Using a skill grants a stack, maximum %d.\nA reagent grants two, " %
				MAX_INSTABILITY_STACKS +
			"is amplified by " + str(_reagent_amplification * 100.0) + "%, and grants a charge.\n" +
			"At maximum stacks the next skill also releases a Surge: damaging everyone.\n" +
			"Stacks reset and a charge is gained.\n" +
			"Each charge makes the next skill Echo once more, spending all of them.\n" +
			"Every Echo hits " + str((_echo_compounding - 1.0) * 100.0) + "% harder than the last.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Reagent_Consumed] = Callable(self, "OnReagentConsumed")
	_execution_steps[Types.Combat_Event.Zone_Constructed] = Callable(self, "OnZoneConstructed")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_instability_stacks = 0
	_echo_charges = 0
	_echoes_for_this_cast = 0
	_echo_index = 0
	_placed_zone_ID_this_cast = -1
	# Re-subscribed every battle: p_resolver (and its CascadeResolver) is fresh per combat,
	# so there is nothing to unsubscribe from a previous one.
	p_resolver.GetCascadeResolver().SubscribeCascadeContributor(
			func(p_event: CascadeEvent) -> CascadeContribution:
				if(p_event.subject_ID != p_owner_ID or _echoes_for_this_cast <= 0):
					return null
				return CascadeContribution.new(_CASCADE_MECHANIC_KEY, _echoes_for_this_cast,
						CascadeContribution.Kind.Base, 1.0,
						func(e: CascadeEvent) -> void: _OnSkillResolvedRepeat(p_owner_ID, e, p_resolver)),
			Types.Cascade_Trigger.Skill_Resolved)

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_state: String = (_body + "\n" +
			"Current Stacks: " + str(_instability_stacks) + "\n" +
			"Current Charges: " + str(_echo_charges))
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_state, 0)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	_echoes_for_this_cast = _echo_charges
	_echo_charges = 0
	_echo_index = 0
	_placed_zone_ID_this_cast = -1
	var releases_surge: bool = _instability_stacks >= MAX_INSTABILITY_STACKS

	if not releases_surge:
		_instability_stacks = min(_instability_stacks + 1, MAX_INSTABILITY_STACKS)

	if releases_surge:
		_ReleaseSurge(p_owner_ID, p_caster_attributes, p_resolver)
		_instability_stacks = 0
		_echo_charges += 1

	return result

func OnReagentConsumed(
		_p_consumer_ID: int, _p_reagent: ReagentData, _p_resolver: BattleResolver) -> float:
	_instability_stacks = min(_instability_stacks + 2, MAX_INSTABILITY_STACKS)
	_echo_charges += 1
	return _reagent_amplification

func OnZoneConstructed(_p_owner_ID: int, p_zone_ID: int, _p_resolver: BattleResolver) -> void:
	_placed_zone_ID_this_cast = p_zone_ID

func _OnSkillResolvedRepeat(p_owner_ID: int, p_event: CascadeEvent, p_resolver: BattleResolver) -> void:
	var index: int = _echo_index
	_echo_index += 1
	if(index + 1 >= _echoes_for_this_cast):
		_echoes_for_this_cast = 0

	if(-1 != _placed_zone_ID_this_cast and p_resolver.GetZoneResolver().HasZone(_placed_zone_ID_this_cast)):
		p_resolver.GetZoneResolver().AmplifyZoneDamage(_placed_zone_ID_this_cast, ECHO_ZONE_AMPLIFICATION)
		return

	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	if(not characters.has(p_owner_ID)):
		return
	var caster: Character = characters[p_owner_ID]
	if(p_event.skill_ID < 0 or p_event.skill_ID >= caster._skills.size()):
		return
	var cast_skill: Skill = caster._skills[p_event.skill_ID]
	var caster_attributes: Dictionary[Types.Attribute, int] = p_resolver.GetEffectiveAttributes(p_owner_ID)
	# A fresh context: the repeat is its own instance (Concept_Document.md 1.1.3's cascade
	# definition), not a continuation of the original cast's TraitSkillResult or use count.
	var context := SkillCastContext.new(p_resolver, p_owner_ID, p_event.target_IDs, cast_skill,
			caster_attributes, 0, TraitSkillResult.new())
	context.repeat_bonus = REPEAT_FRACTION * pow(_echo_compounding, float(index)) - 1.0
	for effect in cast_skill.effects:
		if(effect is DamageEffect and context.ConditionMet(effect)):
			effect.Resolve(context)

func _ReleaseSurge(
		p_owner_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> void:
	var all_target_IDs: Array[int] = p_resolver.GetSides().AllMembers()
	p_resolver.ResolveTraitDamage(p_owner_ID, all_target_IDs, p_caster_attributes,
			{Types.Attribute.Mysticism: SURGE_MYSTICISM_SCALING}, false)
