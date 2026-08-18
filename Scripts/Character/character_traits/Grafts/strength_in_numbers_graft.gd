class_name StrengthInNumbersGraft extends GraftEffect

const RESISTANCE_DEFENCE_BONUS_PER_ALLY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.08,
	Types.Rarity.Rare: 0.10,
	Types.Rarity.Epic: 0.12,
	Types.Rarity.Legendary: 0.14,
}

const NO_ALLY_PENALTY: float = -0.25
const MAX_SCALING_ALLIES: int = 2

var _bonus_per_ally: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_bonus_per_ally = RESISTANCE_DEFENCE_BONUS_PER_ALLY.get(p_rarity, 0.0)
	_title = "Strength in Numbers"
	_body = ("Gains " + str(roundi(_bonus_per_ally * 100)) + "% Resistance and Defense for each other"
			+ " living ally, up to two. While alone, loses " + str(roundi(-NO_ALLY_PENALTY * 100))
			+ "% Resistance instead.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")
	_execution_steps[Types.Combat_Event.Ally_Death] = Callable(self, "OnAllyDeath")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_Recompute(p_owner_ID, p_resolver)

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_Recompute(p_owner_ID, p_resolver)

func OnAllyDeath(p_owner_ID: int, _p_dead_ally_ID: int, p_resolver: BattleResolver) -> void:
	_Recompute(p_owner_ID, p_resolver)

func _Recompute(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	allies.erase(p_owner_ID)
	var ally_count: int = mini(allies.size(), MAX_SCALING_ALLIES)

	if(0 == ally_count):
		_attribute_percent_delta = {Types.Attribute.Resistance: NO_ALLY_PENALTY}
	else:
		var bonus: float = _bonus_per_ally * ally_count
		_attribute_percent_delta = {Types.Attribute.Resistance: bonus, Types.Attribute.Defence: bonus}
