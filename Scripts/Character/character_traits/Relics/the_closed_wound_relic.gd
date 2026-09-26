class_name TheClosedWoundRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("Damaging skills deal +" + str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"No one on the wearer's team can be healed, by any source.")

func GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
	return Magnitude()

func GetTeamHealMultiplier() -> float:
	return 0.0
