class_name SorcererTrait extends CharacterTrait

const MYSTICISM_PER_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.04,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.10,
}

const REAGENT_AMPLIFICATION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.20,
	Types.Rarity.Rare: 0.30,
	Types.Rarity.Epic: 0.40,
	Types.Rarity.Legendary: 0.50,
}

const MAX_INSTABILITY_STACKS: int = 5

# Damage coefficient scaling Surge with the Sorcerer's Mysticism.
const SURGE_MYSTICISM_SCALING: float = 1.5

# Fraction of the repeated skill's damage the reagent-triggered repeat deals, contributed
# as a CombinedDamageModifier bucket (Contribute(key, REPEAT_BONUS), i.e. -0.5 -> 50%).
const REPEAT_FRACTION: float = 0.5
const REPEAT_BONUS: float = REPEAT_FRACTION - 1.0

# Cascade mechanic identity for the Skill_Resolved subscription (Concept_Document.md
# 1.1.3's composition-law currency) — a trait resource, not this Sorcerer's character
# identity, so two Sorcerers on the same team dedup independently by subject_ID.
const _CASCADE_MECHANIC_KEY: StringName = &"SorcererTrait"

var _instability_stacks: int = 0
var _mysticism_per_stack: float = 0.0
var _reagent_amplification: float = 0.0
# Set by OnReagentConsumed, cleared when the repeat fires (or a fresh battle starts):
# whether this Sorcerer has consumed a reagent since their last cast.
var _consumed_reagent_since_cast: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_mysticism_per_stack = MYSTICISM_PER_STACK.get(p_rarity, 0.0)
	_reagent_amplification = REAGENT_AMPLIFICATION.get(p_rarity, 0.0)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Arcane_Instability/arcane_instability_trait.png"
	)
	_title = "Arcane Instability"
	_body = ("Using any skill grants an Instability stack that gives more Mysticism per stack. " +
			"Consuming a reagent grants two stacks, amplifies the reagent's effect, and makes " +
			"the Sorcerer's next skill repeat at %d%% damage. " % int(REPEAT_FRACTION * 100) +
			"At maximum stacks, the next skill also releases a Surge: damage to all " +
			"characters, allies and the Sorcerer included, then all stacks reset.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Reagent_Consumed] = Callable(self, "OnReagentConsumed")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_instability_stacks = 0
	_consumed_reagent_since_cast = false
	# Re-subscribed every battle: p_resolver (and its CascadeResolver) is fresh per combat,
	# so there is nothing to unsubscribe from a previous one.
	p_resolver.GetCascadeResolver().Subscribe(
			Types.Cascade_Trigger.Skill_Resolved,
			_CASCADE_MECHANIC_KEY,
			func(p_event: CascadeEvent) -> bool: return p_event.subject_ID == p_owner_ID and _consumed_reagent_since_cast,
			func(p_event: CascadeEvent) -> void: _OnSkillResolvedRepeat(p_owner_ID, p_event, p_resolver))

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_stacks: String = (_body + "\n" +
			"Current Instability Stacks: " + str(_instability_stacks))
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_stacks, 0)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	var releases_surge: bool = _instability_stacks >= MAX_INSTABILITY_STACKS

	if not releases_surge:
		_instability_stacks = min(_instability_stacks + 1, MAX_INSTABILITY_STACKS)

	if _instability_stacks > 0:
		p_caster_attributes[Types.Attribute.Mysticism] += int(ceilf(
				p_caster_attributes[Types.Attribute.Mysticism] * _mysticism_per_stack * _instability_stacks))

	if releases_surge:
		_ReleaseSurge(p_owner_ID, p_caster_attributes, p_resolver)
		_instability_stacks = 0

	return result

func OnReagentConsumed(
		_p_consumer_ID: int, _p_reagent: ReagentData, _p_resolver: BattleResolver) -> float:
	_instability_stacks = min(_instability_stacks + 2, MAX_INSTABILITY_STACKS)
	_consumed_reagent_since_cast = true
	return _reagent_amplification

func _OnSkillResolvedRepeat(p_owner_ID: int, p_event: CascadeEvent, p_resolver: BattleResolver) -> void:
	_consumed_reagent_since_cast = false
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
	context.repeat_bonus = REPEAT_BONUS
	for effect in cast_skill.effects:
		if(effect is DamageEffect and context.ConditionMet(effect)):
			effect.Resolve(context)

func _ReleaseSurge(
		p_owner_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> void:
	# Like every other ResolveTraitDamage call (e.g. Overflow's cascade damage), Surge still
	# picks up the caster's persistent channel-2 factors (trait bonus, reagent/graft bonus,
	# Opportunist) via _ContributePersistentCasterFactors inside _ResolveDamage, but carries
	# no skill/ramp/trait-resource bucket — those belong to a specific cast Skill, and Surge
	# is trait damage, not a skill effect. Deliberate, not a gap this phase closes.
	var all_target_IDs: Array[int] = p_resolver.GetSides().AllMembers()
	p_resolver.ResolveTraitDamage(p_owner_ID, all_target_IDs, p_caster_attributes,
			{Types.Attribute.Mysticism: SURGE_MYSTICISM_SCALING}, false)
