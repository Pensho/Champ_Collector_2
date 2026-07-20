class_name LancerTrait extends CharacterTrait

const MOMENTUM_PER_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.04,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.10,
}

const PHALANX_GUARD_DEFENSE: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.04,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.10,
}

const MAX_MOMENTUM_STACKS: int = 5

# Offensive skill name set — keyed by name for O(1) lookup.
const OFFENSIVE_SKILL_NAMES: Dictionary[String, bool] = {
	"Stab": true,
	"Disarm": true,
}

# Defensive skill name set — populated when the preset gains a defensive skill.
# Declared as var so subclasses and tests can extend it without modifying the const.
var defensive_skill_names: Dictionary[String, bool] = {}

var _momentum_stacks: int = 0
var _momentum_per_stack: float = 0.0
var _phalanx_guard_defense: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_momentum_per_stack = MOMENTUM_PER_STACK.get(p_rarity, 0.0)
	_phalanx_guard_defense = PHALANX_GUARD_DEFENSE.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Status_Effects/Phalanx_Guard/Phalanx_Guard.jpg")
	_title = "Reckless Momentum"
	_body = ("Offensive skills grant a Momentum stack that gives more Attack and less Defense per stack. " +
			"Using a defensive skill grants Phalanx Guard and consumes all stacks.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Defend] = Callable(self, "OnDefend")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_momentum_stacks = 0

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_stacks: String = (_body + "\n" +
			"Current Momentum Stacks: " + str(_momentum_stacks))
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_stacks, 0)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()

	if OFFENSIVE_SKILL_NAMES.has(p_skill_name):
		_momentum_stacks = min(_momentum_stacks + 1, MAX_MOMENTUM_STACKS)
	elif defensive_skill_names.has(p_skill_name):
		if _momentum_stacks > 0:
			_momentum_stacks = 0
			var phalanx_guard_buff: StatusEffects.Buff = StatusEffects.Buff.new()
			phalanx_guard_buff.type = Types.Buff_Type.Phalanx_Guard
			phalanx_guard_buff.duration = 2
			phalanx_guard_buff.value = _phalanx_guard_defense
			phalanx_guard_buff.name = "Phalanx Guard"
			p_resolver.ApplyBuff(p_owner_ID, phalanx_guard_buff)

	if _momentum_stacks > 0:
		p_caster_attributes[Types.Attribute.Attack] += int(
				ceilf(p_caster_attributes[Types.Attribute.Attack] * _momentum_per_stack * _momentum_stacks))

	return result

func OnDefend(
		_p_defender_ID: int,
		p_defender_attributes: Dictionary[Types.Attribute, int],
		_p_characters: Dictionary[int, Character]) -> void:
	if _momentum_stacks == 0:
		return
	var penalty: int = int(ceilf(
			p_defender_attributes[Types.Attribute.Defence] * (_momentum_per_stack / 2.0) * _momentum_stacks))
	p_defender_attributes[Types.Attribute.Defence] = max(0, p_defender_attributes[Types.Attribute.Defence] - penalty)
