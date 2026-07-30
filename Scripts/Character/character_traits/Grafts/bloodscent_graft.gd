class_name BloodscentGraft extends GraftEffect

const LOWEST_HEALTH_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.20,
	Types.Rarity.Rare: 0.25,
	Types.Rarity.Epic: 0.30,
	Types.Rarity.Legendary: 0.35,
}

const KILL_HEAL_FRACTION: float = 0.15
const ABOVE_HALF_PENALTY: float = 0.25
const HALF_HEALTH_THRESHOLD: float = 0.5

var _lowest_health_bonus: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_lowest_health_bonus = LOWEST_HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0)
	_title = "Bloodscent"
	_body = ("Deals " + str(int(ABOVE_HALF_PENALTY * 100)) + "% less damage to any enemy above 50% Health."
			+ "Otherwise, deal " + str(int(_lowest_health_bonus * 100)) + "% more damage to the enemy"
			+ " with the lowest current Health, and heals 15% of its own max Health on a killing blow.")
	_execution_steps[Types.Combat_Event.On_Kill] = Callable(self, "OnKill")

func OnKill(p_owner_ID: int, _p_victim_ID: int, p_resolver: BattleResolver) -> void:
	p_resolver.ResolveTraitHeal([p_owner_ID], KILL_HEAL_FRACTION)

func GetOutgoingDamageBonus(p_owner_ID: int, p_target_ID: int, p_resolver: BattleResolver) -> float:
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var target: Character = characters[p_target_ID]
	if(float(target._current_health) > HALF_HEALTH_THRESHOLD * float(p_resolver.GetMaxHealth(p_target_ID))):
		return -ABOVE_HALF_PENALTY
	var enemies: Array[int] = p_resolver.GetSides().EnemiesOf(p_owner_ID).AliveMembers(characters)
	if(enemies.is_empty()):
		return 0.0
	var lowest_ID: int = enemies[0]
	for enemy_ID in enemies:
		if(characters[enemy_ID]._current_health < characters[lowest_ID]._current_health):
			lowest_ID = enemy_ID
	return _lowest_health_bonus if p_target_ID == lowest_ID else 0.0
