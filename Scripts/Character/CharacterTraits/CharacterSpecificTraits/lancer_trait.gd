class_name LancerTrait extends CharacterTrait

const MOMENTUM_PER_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.04,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.10,
}

const RADIANCE_DEFENSE: Dictionary[Types.Rarity, float] = {
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

func Init() -> void:
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Status_Effects/Radiance/Radiance.jpg")
	_title = "Reckless Momentum"
	_body = "Offensive skills grant a Momentum stack that gives more Attack and less Defense per stack. Using a defensive skill grants Radiance and consumes all stacks."
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Defend] = Callable(self, "OnDefend")

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	_momentum_stacks = 0
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_characters: Dictionary[int, Character],
		p_character_repr: Array[CharacterRepresentation],
		p_skill_name: String,
		p_battle_ui: BattleUI,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	var rarity: Types.Rarity = p_characters[p_owner_ID]._rarity
	
	if OFFENSIVE_SKILL_NAMES.has(p_skill_name):
		_momentum_stacks = min(_momentum_stacks + 1, MAX_MOMENTUM_STACKS)
	elif defensive_skill_names.has(p_skill_name):
		if _momentum_stacks > 0:
			_momentum_stacks = 0
			var radiance_buff: StatusEffects.Buff = StatusEffects.Buff.new()
			radiance_buff.type = Types.Buff_Type.Radiance
			radiance_buff.duration = 2
			radiance_buff.value = RADIANCE_DEFENSE.get(rarity, 0.0)
			radiance_buff.name = "Radiance"
			Skills.ApplyBuff(p_characters[p_owner_ID], radiance_buff, p_character_repr[p_owner_ID], p_battle_ui)
	
	if _momentum_stacks > 0:
		var bonus_per_stack: float = MOMENTUM_PER_STACK.get(rarity, 0.0)
		p_caster_attributes[Types.Attribute.Attack] += int(ceilf(p_caster_attributes[Types.Attribute.Attack] * bonus_per_stack * _momentum_stacks))
	
	_body = "Offensive skills grant a Momentum stack that gives more Attack and less Defense per stack. Using a defensive skill grants Radiance and consumes all stacks.\nCurrent Momentum Stacks: " + str(_momentum_stacks)
	p_character_repr[p_owner_ID].SetTraitElementToolTip(_title, _body, 0)
	
	return result

func OnDefend(
		p_defender_ID: int,
		p_defender_attributes: Dictionary[Types.Attribute, int],
		p_characters: Dictionary[int, Character]) -> void:
	if _momentum_stacks == 0:
		return
	var rarity: Types.Rarity = p_characters[p_defender_ID]._rarity
	var penalty: int = int(ceilf(p_defender_attributes[Types.Attribute.Defence] * (MOMENTUM_PER_STACK.get(rarity, 0.0) / 2.0) * _momentum_stacks))
	p_defender_attributes[Types.Attribute.Defence] = max(0, p_defender_attributes[Types.Attribute.Defence] - penalty)
