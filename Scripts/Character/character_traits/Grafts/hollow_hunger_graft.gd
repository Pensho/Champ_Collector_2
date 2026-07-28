class_name HollowHungerGraft extends GraftEffect

const LIFESTEAL_FRACTION_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.10,
	Types.Rarity.Rare: 0.13,
	Types.Rarity.Epic: 0.16,
	Types.Rarity.Legendary: 0.19,
}

var _lifesteal_fraction: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_lifesteal_fraction = LIFESTEAL_FRACTION_PER_RARITY.get(p_rarity, 0.0)
	_title = "Hollow Hunger"
	_body = ("Heals for " + str(int(_lifesteal_fraction * 100))
			+ "% of the damage it deals. Losing 15% max Health.")
	_execution_steps[Types.Combat_Event.Damage_Dealt] = Callable(self, "OnDamageDealt")

func OnDamageDealt(
		p_owner_ID: int, _p_target_ID: int, p_amount: int, p_resolver: BattleResolver) -> void:
	var lifesteal: int = int(round(p_amount * _lifesteal_fraction))
	if(lifesteal > 0):
		p_resolver.ResolveTraitHeal([p_owner_ID], 0.0, lifesteal)

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Health: -0.15}
