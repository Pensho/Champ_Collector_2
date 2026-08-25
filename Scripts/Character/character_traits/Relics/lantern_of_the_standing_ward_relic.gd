class_name LanternOfTheStandingWardRelic extends RelicEffect

const TEAM_REAGENT_PENALTY: float = -0.50

var _echoed_zone_IDs: Dictionary[int, bool] = {}

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/Relics/" +
			"Lantern_of_the_Standing_Ward/Lantern_of_the_Standing_Ward.png")
	_title = "Lantern of the Standing Ward"
	_magnitude_by_rarity = [0.40, 0.45, 0.50, 0.60, 0.75]
	_body = ("Each zone the wearer places Echoes once for the first charge spent, at " +
			str(roundi(Magnitude() * 100)) + "% strength.\n" +
			"Every reagent consumed by anyone on the wearer's team has 50% effect.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Zone_Constructed] = Callable(self, "OnZoneConstructed")
	_execution_steps[Types.Combat_Event.Zone_Used] = Callable(self, "OnZoneUsed")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_echoed_zone_IDs.clear()

func GetTeamReagentPotencyBonus(_p_owner_ID: int, _p_resolver: BattleResolver) -> float:
	return TEAM_REAGENT_PENALTY

func OnZoneConstructed(_p_owner_ID: int, p_zone_ID: int, _p_resolver: BattleResolver) -> void:
	_echoed_zone_IDs[p_zone_ID] = false

func OnZoneUsed(_p_owner_ID: int, p_user_ID: int, p_zone_ID: int, p_resolver: BattleResolver) -> void:
	if(not _echoed_zone_IDs.has(p_zone_ID) or _echoed_zone_IDs[p_zone_ID]):
		return
	_echoed_zone_IDs[p_zone_ID] = true
	p_resolver.GetZoneResolver().ResolveZoneEffectEcho(p_zone_ID, p_user_ID, Magnitude())
