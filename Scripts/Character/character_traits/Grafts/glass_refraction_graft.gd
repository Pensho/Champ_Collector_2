class_name GlassRefractionGraft extends GraftEffect

const MYSTICISM_BACKLASH: float = 0.25

const MYSTICISM_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.12,
	Types.Rarity.Rare: 0.16,
	Types.Rarity.Epic: 0.20,
	Types.Rarity.Legendary: 0.24,
}

const RESISTANCE_DRAWBACK: float = -0.40

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_title = "Glass Refraction"
	_body = ("When hit by an attack, a chaotic backlash strikes the attacker for magical damage"
			+ " equal to " + str(int(MYSTICISM_BACKLASH * 100)) + "% of its own Mysticism. Gains "
			+ str(int(MYSTICISM_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100)) + "% Mysticism, at the cost of "
			+ str(int(-RESISTANCE_DRAWBACK * 100)) + "% Resistance.")
	_execution_steps[Types.Combat_Event.Damage_Taken] = Callable(self, "OnDamageTaken")

func OnDamageTaken(p_owner_ID: int, p_attacker_ID: int, p_resolver: BattleResolver) -> float:
	if(p_attacker_ID != p_owner_ID and p_resolver.GetCharacters().has(p_attacker_ID)
			and p_resolver.GetCharacters()[p_attacker_ID]._current_health > 0):
		p_resolver.ResolveTraitDamage(p_owner_ID, [p_attacker_ID], p_resolver.GetEffectiveAttributes(p_owner_ID),
				{Types.Attribute.Mysticism: MYSTICISM_BACKLASH}, false)
	return 1.0

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Mysticism: MYSTICISM_BONUS_PER_RARITY.get(p_rarity, 0.0)}

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Resistance: RESISTANCE_DRAWBACK}
