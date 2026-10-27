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
const REAGENT_INSTABILITY: int = 2
const SURGE_MYSTICISM_SCALING: float = 1.4
const REPEAT_FRACTION: float = 0.5
const ECHOING_SKILL_NAME: String = "Cataclysm"

# Cascade mechanic identity for the Skill_Resolved subscription (Concept_Document.md
# 1.1.3's composition-law currency) — a trait resource, not this Sorcerer's character
# identity, so two Sorcerers on the same team dedup independently by subject_ID.
const _CASCADE_MECHANIC_KEY: StringName = &"SorcererTrait"

var _instability_stacks: int = 0
var _echo_compounding: float = 1.0
var _reagent_amplification: float = 0.0
var _echoes_for_this_cast: int = 0
# 0-based counter driving each Echo's own compounding fraction within one cast's repeat.
var _echo_index: int = 0
# A cast's Instability is gained at its End_Turn, after its Echoes have drained.
var _skill_gain_pending: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_echo_compounding = ECHO_COMPOUNDING.get(p_rarity, 1.0)
	_reagent_amplification = REAGENT_AMPLIFICATION.get(p_rarity, 0.0)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Arcane_Instability/arcane_instability_trait.png"
	)
	_title = "Arcane Instability"
	_body = ("After each skill, gain 1 Instability, up to %d. " % MAX_INSTABILITY_STACKS +
			"Consuming a reagent grants %d and makes the reagent %d%% stronger.\n" %
				[REAGENT_INSTABILITY, roundi(_reagent_amplification * 100.0)] +
			"Gaining Instability at %d releases a Surge that damages everyone, " % MAX_INSTABILITY_STACKS +
			"then resets Instability to 0.\n" +
			"%s Echoes once per Instability held. " % ECHOING_SKILL_NAME +
			"The first Echo hits at %d%%, each later one %d%% harder." %
				[roundi(REPEAT_FRACTION * 100.0), roundi((_echo_compounding - 1.0) * 100.0)])
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.End_Turn] = Callable(self, "EndOfTurn")
	_execution_steps[Types.Combat_Event.Reagent_Consumed] = Callable(self, "OnReagentConsumed")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_instability_stacks = 0
	_echoes_for_this_cast = 0
	_echo_index = 0
	_skill_gain_pending = false
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
	var body_with_state: String = _body + "\n" + "Current Instability: " + str(_instability_stacks)
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_state, 0)

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	_echoes_for_this_cast = _instability_stacks if ECHOING_SKILL_NAME == p_skill_name else 0
	_echo_index = 0
	_skill_gain_pending = true
	return TraitSkillResult.new()

func EndOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	if(not _skill_gain_pending):
		return
	_skill_gain_pending = false
	_GainInstability(p_owner_ID, 1, p_resolver)

func OnReagentConsumed(
		p_consumer_ID: int, _p_reagent: ReagentData, p_resolver: BattleResolver) -> float:
	_GainInstability(p_consumer_ID, REAGENT_INSTABILITY, p_resolver)
	return _reagent_amplification

## A gain that would carry Instability past the maximum releases the Surge instead.
func _GainInstability(p_owner_ID: int, p_amount: int, p_resolver: BattleResolver) -> void:
	if(_instability_stacks + p_amount <= MAX_INSTABILITY_STACKS):
		_instability_stacks += p_amount
		return
	_instability_stacks = 0
	_ReleaseSurge(p_owner_ID, p_resolver.GetEffectiveAttributes(p_owner_ID), p_resolver)

func _OnSkillResolvedRepeat(p_owner_ID: int, p_event: CascadeEvent, p_resolver: BattleResolver) -> void:
	var index: int = _echo_index
	_echo_index += 1
	if(index + 1 >= _echoes_for_this_cast):
		_echoes_for_this_cast = 0

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
