class_name ForesightTrait extends CharacterTrait

const PERCENT_BEHIND_THRESHOLD: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.21,
	Types.Rarity.Rare: 0.24,
	Types.Rarity.Epic: 0.27,
	Types.Rarity.Legendary: 0.30,
}

var _start_of_turn_debuff: StatusEffects.Debuff
var _reach_threshold: float = 0.0

static func GetReachThreshold(p_rarity: Types.Rarity) -> float:
	return PERCENT_BEHIND_THRESHOLD.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_reach_threshold = GetReachThreshold(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/Foresight_Trait/foresight_trait.png")
	_turn_bar_reach = TurnBarReach.new(_reach_threshold, load(
			"res://Assets/Champ_Collector/Icons/Abilities/Passives/Foresight_Trait/foresight_trait_turnbar_texture.jpg"),
			0.45)
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

	_start_of_turn_debuff = StatusEffects.Debuff.new()
	_start_of_turn_debuff.type = Types.Debuff_Type.Enfeeble
	_start_of_turn_debuff.duration = 1
	_start_of_turn_debuff.name = "Enfeeble"

	_title = "Foresight"
	_body = "Applies Enfeeble to enemies who are close enough behind on the turn bar."

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var enemies_behind: Array[int] = p_resolver.GetTurnPositions().GetCharactersBehindBy(
			p_owner_ID, _reach_threshold)
	if (enemies_behind.is_empty()):
		return

	_start_of_turn_debuff.source_ID = p_owner_ID
	for id in enemies_behind:
		var skill_targets: Array[int] = p_resolver.FindSkillTargets(
				id, p_owner_ID, Types.Skill_Target.Single_Enemy)
		if (skill_targets.has(id)):
			p_resolver.GetStatusResolver().ApplyDebuff(id, _start_of_turn_debuff)
