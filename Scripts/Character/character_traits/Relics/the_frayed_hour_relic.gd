class_name TheFrayedHourRelic extends RelicEffect

const TEAM_BARRIER_MULTIPLIER: float = 0.25

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Frayed_Hour/The_Frayed_Hour.png")
	_title = "The Frayed Hour"
	_magnitude_by_rarity = [200.0, 250.0, 275.0, 300.0, 350.0]
	_body = ("Temporal Leak applied by the wearer has +" + str(roundi(Magnitude())) +
			"% its effect.\n" +
			"Barriers on the wearer's team have 75% less effect.")

func GetAppliedStatusValue(
		p_owner_ID: int, p_target_ID: int, p_debuff_type: Types.Debuff_Type, p_resolver: BattleResolver) -> float:
	if(Types.Debuff_Type.Temporal_Leak != p_debuff_type):
		return -1.0
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff_type)
	if(null == data):
		return -1.0
	var base_value: float = p_resolver.GetStatusResolver().SnapshotStatusValue(data, p_owner_ID, p_target_ID)
	return base_value * (1.0 + Magnitude() / 100.0)

func GetTeamBarrierMultiplier() -> float:
	return TEAM_BARRIER_MULTIPLIER
