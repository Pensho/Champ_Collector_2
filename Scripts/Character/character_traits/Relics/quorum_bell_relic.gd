class_name QuorumBellRelic extends RelicEffect

const TEAM_COOLDOWNLESS_PENALTY: float = 0.30

var _zone_standing: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Quorum_Bell/Quorum_Bell.png")
	_title = "Quorum Bell"
	_magnitude_by_rarity = [11.0, 13.0, 15.0, 17.0, 20.0]
	_body = ("While at least one zone stands on the turn bar, attribute buffs and " +
			"debuffs the wearer applies are +" + str(roundi(Magnitude())) +
			"% points stronger." +
			" Defence, Critical Chance and Critical " +
			"Damage are excluded.\n" +
			"Damaging skills that cannot go on cooldown deal 30% less damage, for everyone " +
			"on the wearer's team.")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

func StartOfTurn(_p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_zone_standing = not p_resolver.GetZoneResolver().GetZones().is_empty()

func GetAppliedAttributeAmplification() -> float:
	return (Magnitude() / 100.0) if _zone_standing else 0.0

func GetTeamCooldownlessDamagePenalty() -> float:
	return TEAM_COOLDOWNLESS_PENALTY
