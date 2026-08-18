class_name UndertowGraft extends GraftEffect

const SELF_TURN_BAR_LOSS: float = 0.05

const PULL_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.06,
	Types.Rarity.Rare: 0.07,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.09,
}

const HEALTH_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.13,
	Types.Rarity.Rare: 0.16,
	Types.Rarity.Epic: 0.19,
	Types.Rarity.Legendary: 0.22,
}

var _pull: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_pull = PULL_PER_RARITY.get(p_rarity, 0.0)
	_title = "Undertow"
	_body = ("When hit by an enemy, pulls that attacker back " + str(roundi(_pull * 100))
			+ "% on the turn bar, at the cost of losing " + str(roundi(SELF_TURN_BAR_LOSS * 100))
			+ "% of its own. Gains " + str(roundi(HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100)) + "% Health.")
	_execution_steps[Types.Combat_Event.Damage_Taken] = Callable(self, "OnDamageTaken")

func OnDamageTaken(p_owner_ID: int, p_attacker_ID: int, p_resolver: BattleResolver) -> float:
	if(p_attacker_ID != p_owner_ID and p_resolver.GetSides().EnemiesOf(p_owner_ID).Has(p_attacker_ID)):
		p_resolver.BumpTurnBar(p_attacker_ID, -_pull, p_owner_ID)
		p_resolver.BumpTurnBar(p_owner_ID, -SELF_TURN_BAR_LOSS)
	return 1.0

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Health: HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0)}
