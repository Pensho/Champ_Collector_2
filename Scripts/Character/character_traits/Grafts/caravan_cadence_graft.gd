class_name CaravanCadenceGraft extends GraftEffect

const TURN_BAR_PUSH_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.07,
	Types.Rarity.Rare: 0.08,
	Types.Rarity.Epic: 0.09,
	Types.Rarity.Legendary: 0.10,
}

const KNOWLEDGE_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.15,
	Types.Rarity.Rare: 0.20,
	Types.Rarity.Epic: 0.25,
	Types.Rarity.Legendary: 0.30,
}

var _push: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_push = TURN_BAR_PUSH_PER_RARITY.get(p_rarity, 0.0)
	_title = "Caravan Cadence"
	_body = ("At the start of its turn, pushes the ally furthest behind themself on the turn bar"
			+ " forward " + str(int(_push * 100)) + "%. Gains "
			+ str(int(KNOWLEDGE_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100)) + "% Knowledge."
			+ " Can never be pushed forward on the turn bar itself.")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var allies_behind: Array[int] = p_resolver.GetTurnPositions().GetCharactersBehindOrdered(p_owner_ID)
	if(allies_behind.is_empty()):
		return
	var skill_targets: Array[int] = p_resolver.FindSkillTargets(
			p_owner_ID, p_owner_ID, Types.Skill_Target.All_Other_Allies)
	if(skill_targets.is_empty()):
		return
	for id in allies_behind:
		if(skill_targets.has(id)):
			p_resolver.BumpTurnBar(id, _push, p_owner_ID)
			return

func BlocksForwardTurnBarBump(_p_owner_ID: int) -> bool:
	return true

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Knowledge: KNOWLEDGE_BONUS_PER_RARITY.get(p_rarity, 0.0)}
