class_name CarrionBloomGraft extends GraftEffect

const HEALTH_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.10,
	Types.Rarity.Rare: 0.12,
	Types.Rarity.Epic: 0.14,
	Types.Rarity.Legendary: 0.16,
}

const HEAL_FRACTION_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.03,
	Types.Rarity.Rare: 0.04,
	Types.Rarity.Epic: 0.05,
	Types.Rarity.Legendary: 0.06,
}

const SELF_HEAL_MULTIPLIER: float = 0.5

var _heal_fraction: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_heal_fraction = HEAL_FRACTION_PER_RARITY.get(p_rarity, 0.0)
	_title = "Carrion Bloom"
	_body = ("Gains " + str(int(HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100)) + "% max Health."
			+ "\nAt the start of its turn, heals the lowest-Health living ally for "
			+ str(int(_heal_fraction * 100)) + "% of that ally's max Health."
			+ "\nHealing it receives itself is reduced by "
			+ str(int((1.0 - SELF_HEAL_MULTIPLIER) * 100)) + "%.")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(
			p_resolver.GetCharacters())
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var lowest_ID: int = allies[0]
	for ally_ID in allies:
		if(characters[ally_ID]._current_health < characters[lowest_ID]._current_health):
			lowest_ID = ally_ID
	p_resolver.ResolveTraitHeal([lowest_ID], _heal_fraction)

func GetIncomingHealMultiplier(_p_owner_ID: int) -> float:
	return SELF_HEAL_MULTIPLIER

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Health: HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0)}
