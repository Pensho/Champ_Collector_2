class_name TheLongSecondRelic extends RelicEffect

const TEAM_BUFF_MULTIPLIER: float = 0.70

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_magnitude_by_rarity = [0.20, 0.25, 0.30, 0.35, 0.45]
	_body = ("Forward turn-bar bumps the wearer grants an ally gain +" +
			str(roundi(Magnitude() * 100)) + "% increased effect.\n" +
			"Buffs placed by the wearer's team have 30% reduced effect.")

func GetOutgoingAllyTurnBarBumpAmplification(_p_owner_ID: int) -> float:
	return Magnitude()

func GetTeamAppliedBuffMultiplier() -> float:
	return TEAM_BUFF_MULTIPLIER
