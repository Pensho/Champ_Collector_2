class_name UnderstudysCoatRelic extends RelicEffect

const DAMAGE_DRAWBACK: float = 0.35

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Understudys_Coat/Understudys_Coat.png")
	_title = "Understudy's Coat"
	_magnitude_by_rarity = [0.85, 0.80, 0.75, 0.70, 0.60]
	_body = ("Enemy single-target skills aimed at any other ally with the lowest " +
			"current Health redirect " + str(roundi(Magnitude() * 100)) +
			"% of the damage to the wearer.\n" +
			"The wearer's damaging skills deal 35% less damage.")
	_execution_steps[Types.Combat_Event.Ally_Damage_Taken] = Callable(self, "OnAllyDamageTaken")

func OnAllyDamageTaken(
		p_owner_ID: int, p_damaged_ally_ID: int, p_resolver: BattleResolver) -> float:
	if(p_owner_ID == p_damaged_ally_ID):
		return 0.0
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var owner: Character = characters.get(p_owner_ID)
	if(null == owner or owner._current_health <= 0):
		return 0.0
	var team: CombatTeam = p_resolver.GetSides().AlliesOf(p_owner_ID)
	if(null == team):
		return 0.0
	var allies: Array[int] = team.AliveMembers(characters)
	allies.erase(p_owner_ID)
	if(allies.is_empty()):
		return 0.0
	var lowest_ID: int = Skills.MostInjured(allies, characters, Callable(p_resolver, "GetMaxHealth"))
	if(lowest_ID != p_damaged_ally_ID):
		return 0.0
	return Magnitude()

func GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
	return -DAMAGE_DRAWBACK
