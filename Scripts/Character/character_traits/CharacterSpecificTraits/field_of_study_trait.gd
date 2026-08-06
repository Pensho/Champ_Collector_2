class_name FieldOfStudyTrait extends CharacterTrait

const WEAKNESS_REDUCTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.04,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.10,
}

const PRIMARY_ATTRIBUTES: Array[Types.Attribute] = [
	Types.Attribute.Attack,
	Types.Attribute.Defence,
	Types.Attribute.Accuracy,
	Types.Attribute.Resistance,
	Types.Attribute.Mysticism,
	Types.Attribute.Knowledge,
]

var _reduction: float = 0.0
var _weakness_by_enemy: Dictionary[int, Types.Attribute] = {}

static func GetWeaknessReduction(p_rarity: Types.Rarity) -> float:
	return WEAKNESS_REDUCTION.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_reduction = GetWeaknessReduction(p_rarity)
	_trait_texture = load(
			"res://Assets/Champ_Collector/Icons/Abilities/Passives/Field_Of_Study_Trait/field_of_study_trait.png")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Debuff_Applied] = Callable(self, "OnDebuffApplied")

	_title = "Field of Study"
	_body = ("Identifies each enemy's weakest primary attribute at combat start. Debuffs" \
			+ " from the Scholar reduce that attribute an extra " + str(_reduction * 100) + "%.")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_weakness_by_enemy.clear()
	var enemies: Array[int] = p_resolver.GetSides().EnemiesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	for enemy_ID in enemies:
		_weakness_by_enemy[enemy_ID] = _IdentifyWeakness(
				p_resolver.GetEffectiveAttributes(enemy_ID), p_resolver.GetRandom())

func OnDebuffApplied(
		_p_owner_ID: int,
		p_target_ID: int,
		p_debuff: StatusEffects.Debuff,
		_p_resolver: BattleResolver) -> void:
	if(not _weakness_by_enemy.has(p_target_ID)):
		return
	p_debuff.has_weakness_rider = true
	p_debuff.weakness_attribute = _weakness_by_enemy[p_target_ID]
	p_debuff.weakness_reduction = _reduction

func _IdentifyWeakness(
		p_attributes: Dictionary[Types.Attribute, int],
		p_random: RandomNumberGenerator) -> Types.Attribute:
	var highest_value: int = -1
	var candidates: Array[Types.Attribute] = []
	for attribute in PRIMARY_ATTRIBUTES:
		if(p_attributes[attribute] > highest_value):
			highest_value = p_attributes[attribute]
			candidates = [attribute]
		elif(p_attributes[attribute] == highest_value):
			candidates.append(attribute)
	return candidates[p_random.randi_range(0, candidates.size() - 1)]
