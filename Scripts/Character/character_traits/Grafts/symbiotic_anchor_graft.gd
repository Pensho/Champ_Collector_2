class_name SymbioticAnchorGraft extends GraftEffect

const SHARE_FRACTION: float = 0.20

const RESISTANCE_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.14,
	Types.Rarity.Rare: 0.16,
	Types.Rarity.Epic: 0.18,
	Types.Rarity.Legendary: 0.20,
}

const DEFENCE_PENALTY: float = -0.30
const CRIT_DAMAGE_PENALTY: float = -0.30

var _tethered_ally_ID: int = -1

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_title = "Symbiotic Anchor"
	_body = ("Tethers to a random living ally, sharing " + str(roundi(SHARE_FRACTION * 100))
			+ "% of this Symbiote's Resistance and Attack. Re-tethers to a new ally if the"
			+ " tethered ally dies. Gains " + str(roundi(RESISTANCE_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100))
			+ "% Resistance, but loses " + str(roundi(-DEFENCE_PENALTY * 100)) + "% Defense and "
			+ str(roundi(-CRIT_DAMAGE_PENALTY * 100)) + "% Crit Damage.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Ally_Death] = Callable(self, "OnAllyDeath")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_Tether(p_owner_ID, p_resolver)

func OnAllyDeath(p_owner_ID: int, p_dead_ally_ID: int, p_resolver: BattleResolver) -> void:
	if(p_dead_ally_ID == _tethered_ally_ID):
		_Tether(p_owner_ID, p_resolver)

func _Tether(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	allies.erase(p_owner_ID)
	if(allies.is_empty()):
		_tethered_ally_ID = -1
		return
	_tethered_ally_ID = allies[p_resolver.GetRandom().randi_range(0, allies.size() - 1)]

	var symbiote: Character = p_resolver.GetCharacters()[p_owner_ID]
	var share_resistance: int = int(ceilf(symbiote.GetTotalAttribute(Types.Attribute.Resistance) * SHARE_FRACTION))
	var share_attack: int = int(ceilf(symbiote.GetTotalAttribute(Types.Attribute.Attack) * SHARE_FRACTION))
	p_resolver.AdjustLongAttributeBonus(_tethered_ally_ID, Types.Attribute.Resistance, share_resistance)
	p_resolver.AdjustLongAttributeBonus(_tethered_ally_ID, Types.Attribute.Attack, share_attack)

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Resistance: RESISTANCE_BONUS_PER_RARITY.get(p_rarity, 0.0)}

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Defence: DEFENCE_PENALTY, Types.Attribute.CritDamage: CRIT_DAMAGE_PENALTY}
