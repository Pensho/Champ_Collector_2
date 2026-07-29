class_name ContagionBondGraft extends GraftEffect

const CONTAGION_WIDTH_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.06,
	Types.Rarity.Rare: 0.08,
	Types.Rarity.Epic: 0.10,
	Types.Rarity.Legendary: 0.12,
}

const DEBUFF_DURATION_BONUS: int = 2
const COPY_DURATION: int = 1

var _width: float = 0.0
# Blocks re-entry while a copy is being applied: Buff_Applied/Debuff_Received dispatch
# synchronously, so two Contagion Bond carriers standing within each other's width can
# otherwise ping-pong a copy back and forth on the same call stack indefinitely.
var _relaying: bool = false

static func GetReachThreshold(p_rarity: Types.Rarity) -> float:
	return CONTAGION_WIDTH_PER_RARITY.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_width = GetReachThreshold(p_rarity)
	_title = "Contagion Bond"
	_body = ("When it gains a buff, the nearest ally within " + str(int(_width * 100))
			+ "% of the turn bar gains a copy for 1 turn. When a debuff lands on it, the"
			+ " nearest enemy within that width catches a copy, contested against the"
			+ " enemy's Resistance. Debuffs on it last " + str(DEBUFF_DURATION_BONUS)
			+ " turns longer.")
	_execution_steps[Types.Combat_Event.Buff_Applied] = Callable(self, "OnBuffGained")
	_execution_steps[Types.Combat_Event.Debuff_Received] = Callable(self, "OnDebuffReceived")

func OnBuffGained(p_owner_ID: int, p_buff: StatusEffects.Buff, p_resolver: BattleResolver) -> void:
	if(_relaying):
		return
	var nearby: Array[int] = p_resolver.GetTurnPositions().GetCharactersByProximityOrdered(
			p_owner_ID, _width)
	for id in nearby:
		var ally_targets: Array[int] = p_resolver.FindSkillTargets(
				id, p_owner_ID, Types.Skill_Target.Single_Ally)
		if(not ally_targets.has(id)):
			continue
		var copy: StatusEffects.Buff = StatusEffects.Buff.new()
		copy.type = p_buff.type
		copy.value = p_buff.value
		copy.duration = COPY_DURATION
		copy.name = p_buff.name
		copy.source_ID = p_owner_ID
		_relaying = true
		p_resolver.GetStatusResolver().ApplyBuff(id, copy)
		_relaying = false
		return

func OnDebuffReceived(
		p_owner_ID: int, p_debuff: StatusEffects.Debuff, p_resolver: BattleResolver) -> void:
	if(_relaying):
		return
	var nearby: Array[int] = p_resolver.GetTurnPositions().GetCharactersByProximityOrdered(
			p_owner_ID, _width)
	for id in nearby:
		var enemy_targets: Array[int] = p_resolver.FindSkillTargets(
				id, p_owner_ID, Types.Skill_Target.Single_Enemy)
		if(not enemy_targets.has(id)):
			continue
		var copy: StatusEffects.Debuff = StatusEffects.Debuff.new()
		copy.type = p_debuff.type
		copy.value = p_debuff.value
		copy.duration = COPY_DURATION
		copy.name = p_debuff.name
		copy.source_ID = p_owner_ID
		_relaying = true
		p_resolver.GetStatusResolver().CastDebuff(id, copy, p_owner_ID)
		_relaying = false
		return

func GetIncomingDebuffDurationBonus(_p_owner_ID: int) -> int:
	return DEBUFF_DURATION_BONUS
