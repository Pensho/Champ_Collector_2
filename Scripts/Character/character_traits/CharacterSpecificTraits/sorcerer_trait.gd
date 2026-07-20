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

# Magical damage coefficient scaling Surge with the Sorcerer's Mysticism.
const SURGE_MYSTICISM_SCALING: float = 1.5

var _instability_stacks: int = 0
var _mysticism_per_stack: float = 0.0
var _reagent_amplification: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_mysticism_per_stack = MYSTICISM_PER_STACK.get(p_rarity, 0.0)
	_reagent_amplification = REAGENT_AMPLIFICATION.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Arcane_Instability/Arcane_Instability.png")
	_title = "Arcane Instability"
	_body = ("Using any skill grants an Instability stack that gives more Mysticism per stack. " +
			"Consuming a reagent grants two stacks and amplifies the reagent's effect. " +
			"At maximum stacks, the next skill also releases a Surge: magical damage to all " +
			"characters, allies and the Sorcerer included, then all stacks reset.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Reagent_Consumed] = Callable(self, "OnReagentConsumed")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_instability_stacks = 0

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
	return _reagent_amplification

func _ReleaseSurge(
		p_owner_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> void:
	var all_target_IDs: Array[int] = p_resolver.GetSides().AllMembers()
	p_resolver.ResolveTraitDamage(p_owner_ID, all_target_IDs, p_caster_attributes,
			{Types.Attribute.Mysticism: SURGE_MYSTICISM_SCALING}, false)
