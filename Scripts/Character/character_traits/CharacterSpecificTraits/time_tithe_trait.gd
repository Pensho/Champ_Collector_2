class_name TimeTitheTrait extends CharacterTrait

const TITHE_FRACTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.25,
	Types.Rarity.Rare: 0.35,
	Types.Rarity.Epic: 0.45,
	Types.Rarity.Legendary: 0.55,
}

const BORROWED_TIME_FRACTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.30,
	Types.Rarity.Rare: 0.40,
	Types.Rarity.Epic: 0.50,
	Types.Rarity.Legendary: 0.60,
}

const BORROWED_TIME_DURATION: int = 1

var _tithe_fraction: float = 0.0
var _borrowed_time_fraction: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_tithe_fraction = TITHE_FRACTION.get(p_rarity, 0.0)
	_borrowed_time_fraction = BORROWED_TIME_FRACTION.get(p_rarity, 0.0)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Time_Tithe_Trait/time_tithe_trait.png"
	)
	_title = "Time Tithe"
	_body = ("Stealing turn bar from an enemy absorbs " + str(roundi(_tithe_fraction * 100)) +
			"% of it as own progress.\nMoving an ally forward, with no other ally in their " +
			"turn-bar section, grants Borrowed Time: their next damaging skill resolves once " +
			"more at " + str(roundi(_borrowed_time_fraction * 100)) + "% strength.")
	_execution_steps[Types.Combat_Event.Enemy_Turn_Bar_Reduced] = Callable(self, "OnEnemyTurnBarReduced")
	_execution_steps[Types.Combat_Event.Ally_Turn_Bar_Increased] = Callable(self, "OnAllyTurnBarIncreased")

func OnEnemyTurnBarReduced(
		p_owner_ID: int, p_reduction: float, p_resolver: BattleResolver) -> float:
	var turn_bump: float = p_reduction * _tithe_fraction
	if(0.0 != turn_bump):
		p_resolver.EmitTraitText(p_owner_ID, "Turn claimed")
	return turn_bump

func OnAllyTurnBarIncreased(
		p_owner_ID: int, p_target_ID: int, _p_fraction: float, p_resolver: BattleResolver) -> void:
	var section: int = p_resolver.GetTurnPositions().GetSectionIndex(p_target_ID)
	if(-1 == section):
		return
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_target_ID).AliveMembers(p_resolver.GetCharacters())
	for ally_ID in allies:
		if(ally_ID == p_target_ID):
			continue
		if(section == p_resolver.GetTurnPositions().GetSectionIndex(ally_ID)):
			return

	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Borrowed_Time
	buff.name = "Borrowed Time"
	buff.duration = BORROWED_TIME_DURATION
	buff.value = _borrowed_time_fraction
	buff.source_ID = p_owner_ID
	p_resolver.GetStatusResolver().ApplyBuff(p_target_ID, buff)
	p_resolver.EmitTraitText(p_owner_ID, "Time given")
