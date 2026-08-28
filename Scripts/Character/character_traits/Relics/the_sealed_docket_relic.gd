class_name TheSealedDocketRelic extends RelicEffect

const TEAM_ECHO_STRENGTH: float = 0.5
const _CASCADE_MECHANIC_KEY: StringName = &"TheSealedDocketRelic"

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Sealed_Docket/The_Sealed_Docket.png")
	_title = "The Sealed Docket"
	_magnitude_by_rarity = [0.35, 0.42, 0.50, 0.62, 0.80]
	_body = ("While the target carries four or more distinct debuff types, damaging " +
			"skills deal +" + str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Echoes produced by anyone on the wearer's team resolve at half strength.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	p_resolver.GetCascadeResolver().SubscribeStrengthModifier(
			func(p_event: CascadeEvent) -> CascadeStrength:
				if(not p_resolver.GetSides().AreAllies(p_owner_ID, p_event.origin_ID)):
					return null
				return CascadeStrength.new(_CASCADE_MECHANIC_KEY, TEAM_ECHO_STRENGTH))
