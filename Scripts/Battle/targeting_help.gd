class_name TargetingHelp extends RefCounted

## Decides what the targeting help highlights while the player picks a target: the
## characters an action affects, or the turn-bar sections a zone action can be used on.
## Random target types highlight every character the roll can land on.

static func HighlightedCharacters(
		p_target_type: Types.Skill_Target,
		p_caster_ID: int,
		p_characters: Dictionary[int, Character],
		p_sides: CombatSides,
		p_max_health: Callable) -> Array[int]:
	var allies: Array[int] = p_sides.AlliesOf(p_caster_ID).AliveMembers(p_characters)
	var enemies: Array[int] = p_sides.EnemiesOf(p_caster_ID).AliveMembers(p_characters)
	match p_target_type:
		Types.Skill_Target.Single_Enemy, Types.Skill_Target.All_Enemies, Types.Skill_Target.Random_Enemy:
			return enemies
		Types.Skill_Target.Single_Ally, Types.Skill_Target.All_Allies, Types.Skill_Target.Random_Ally:
			return allies
		Types.Skill_Target.Ally_Not_Self, Types.Skill_Target.All_Other_Allies:
			allies.erase(p_caster_ID)
			return allies
		Types.Skill_Target.Random_One, Types.Skill_Target.All:
			return CombatTeam.new(p_sides.AllMembers()).AliveMembers(p_characters)
		Types.Skill_Target.Self:
			var caster: Array[int] = [p_caster_ID]
			return Skills.FilterAliveTargets(caster, p_characters)
		Types.Skill_Target.Most_Injured_Ally:
			return Skills.SingleTargetArray(Skills.MostInjured(allies, p_characters, p_max_health))
		Types.Skill_Target.Most_Injured_Enemy:
			return Skills.SingleTargetArray(Skills.MostInjured(enemies, p_characters, p_max_health))
		Types.Skill_Target.Most_Buffed_Ally:
			return Skills.SingleTargetArray(Skills.MostBuffed(allies, p_characters))
		Types.Skill_Target.Left_Most_Enemy:
			return Skills.SingleTargetArray(Skills.EdgeMostAlive(enemies, true))
		Types.Skill_Target.Right_Most_Enemy:
			return Skills.SingleTargetArray(Skills.EdgeMostAlive(enemies, false))
	return []

static func HighlightedSections(p_clearing: bool, p_zone_resolver: ZoneResolver) -> Array[int]:
	if(not p_clearing):
		return p_zone_resolver.AvailableZoneIDs()
	var occupied: Array[int] = []
	occupied.assign(p_zone_resolver.GetZones().keys())
	return occupied

static func ReagentTargetType(p_kind: ReagentData.TargetKind) -> Types.Skill_Target:
	if(ReagentData.TargetKind.One_Ally == p_kind):
		return Types.Skill_Target.Single_Ally
	return Types.Skill_Target.Single_Enemy
