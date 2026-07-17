class_name PlanTrait extends CharacterTrait

const PERCENT_BEHIND_THRESHOLD: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.10,
	Types.Rarity.Rare: 0.15,
	Types.Rarity.Epic: 0.20,
	Types.Rarity.Legendary: 0.25,
}

var _start_of_turn_buff: StatusEffects.Buff

static func GetReachThreshold(p_rarity: Types.Rarity) -> float:
	return PERCENT_BEHIND_THRESHOLD.get(p_rarity, 0.0)

func Init() -> void:
	_trait_texture = load("uid://cfaeiuchn2y3o")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

	_start_of_turn_buff = StatusEffects.Buff.new()
	_start_of_turn_buff.type = Types.Buff_Type.Empower
	_start_of_turn_buff.duration = 1
	_start_of_turn_buff.name = "Empower"
	_start_of_turn_buff.stackable = false

	_title = "Plan ahead"
	_body = "Casts Empower on allies who are close enough behind on the turn bar."

func StartOfBattle() -> void:
	pass

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var rarity: Types.Rarity = characters[p_owner_ID]._rarity
	var threshold: float = GetReachThreshold(rarity)

	var allies_behind: Array[int] = p_resolver.GetTurnPositions().GetCharactersBehindBy(p_owner_ID, threshold)
	if (allies_behind.is_empty()):
		return

	var skill_targets: Array[int] = p_resolver.FindSkillTargets(
			p_owner_ID, p_owner_ID, Types.Skill_Target.All_Other_Allies)
	if (skill_targets.is_empty()):
		return

	for id in allies_behind:
		if (skill_targets.has(id)):
			p_resolver.ApplyBuff(id, _start_of_turn_buff)
