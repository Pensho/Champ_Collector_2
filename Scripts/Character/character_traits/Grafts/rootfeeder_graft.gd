class_name RootfeederGraft extends GraftEffect

const HEAL_FRACTION_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.04,
	Types.Rarity.Rare: 0.05,
	Types.Rarity.Epic: 0.06,
	Types.Rarity.Legendary: 0.07,
}

const ENEMY_ZONE_EFFECT_MULTIPLIER: float = 1.5

var _heal_fraction: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_heal_fraction = HEAL_FRACTION_PER_RARITY.get(p_rarity, 0.0)
	_title = "Rootfeeder"
	_body = ("Whenever affected by any zone, heals for " + str(int(_heal_fraction * 100))
			+ "% of max Health on top of the zone's own effect."
			+ "\nZone effects from enemy-owned zones are " + str(int(ENEMY_ZONE_EFFECT_MULTIPLIER * 100))
			+ "% as strong.")
	_execution_steps[Types.Combat_Event.Zone_Affected] = Callable(self, "OnAffectedByZone")

func OnAffectedByZone(p_owner_ID: int, _p_zone_owner_ID: int, p_resolver: BattleResolver) -> void:
	p_resolver.ResolveTraitHeal([p_owner_ID], _heal_fraction)

func GetIncomingZoneEffectMultiplier(
		p_owner_ID: int, p_zone_owner_ID: int, p_sides: CombatSides) -> float:
	return ENEMY_ZONE_EFFECT_MULTIPLIER if p_sides.AreEnemies(p_owner_ID, p_zone_owner_ID) else 1.0
