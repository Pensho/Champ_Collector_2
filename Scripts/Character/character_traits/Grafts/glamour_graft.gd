class_name GlamourGraft extends GraftEffect

const DAMAGE_DEALT_BONUS: float = 0.10
const DAMAGE_TAKEN_MULTIPLIER: float = 1.1
const TARGETING_PRIORITY_MULTIPLIER: float = 1.2

const REDIRECT_CHANCE_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.25,
	Types.Rarity.Rare: 0.30,
	Types.Rarity.Epic: 0.35,
	Types.Rarity.Legendary: 0.40,
}

var _redirect_chance: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_redirect_chance = REDIRECT_CHANCE_PER_RARITY.get(p_rarity, 0.0)
	_title = "Glamour"
	_body = ("Single-target attacks have a " + str(roundi(_redirect_chance * 100))
			+ "% chance to be redirected onto a random other character. Deals "
			+ str(roundi(DAMAGE_DEALT_BONUS * 100)) + "% more damage, but takes "
			+ str(roundi((DAMAGE_TAKEN_MULTIPLIER - 1.0) * 100)) + "% more damage and is targeted "
			+ str(roundi((TARGETING_PRIORITY_MULTIPLIER - 1.0) * 100)) + "% more often.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Damage_Taken] = Callable(self, "OnDamageTaken")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	p_resolver.AggregateDamageMultipliers(p_owner_ID, DAMAGE_DEALT_BONUS)

func OnDamageTaken(_p_owner_ID: int, _p_attacker_ID: int, _p_resolver: BattleResolver) -> float:
	return DAMAGE_TAKEN_MULTIPLIER

func GetIncomingSingleTargetRedirectChance(_p_owner_ID: int) -> float:
	return _redirect_chance

func GetTargetingPriorityMultiplier() -> float:
	return TARGETING_PRIORITY_MULTIPLIER
