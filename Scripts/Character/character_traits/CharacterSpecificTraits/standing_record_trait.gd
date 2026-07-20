class_name StandingRecordTrait extends CharacterTrait

const RATE_PER_INFRACTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.025,
	Types.Rarity.Rare: 0.03,
	Types.Rarity.Epic: 0.035,
	Types.Rarity.Legendary: 0.04,
}

const INFRACTION_CAP: int = 9

var _rate_per_infraction: float = 0.0
var _owner_ID: int = -1
var _resolver: BattleResolver = null
var _infractions: Dictionary[int, int] = {}

static func GetRatePerInfraction(p_rarity: Types.Rarity) -> float:
	return RATE_PER_INFRACTION.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_rate_per_infraction = GetRatePerInfraction(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Break_Guard/Break_Guard.jpg")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

	_title = "Standing Record"
	_body = "Every enemy has a personal Infraction tally, up to 9, that grows whenever they" \
			+ " gain a buff, place a zone, or land a debuff on an ally."

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_owner_ID = p_owner_ID
	_resolver = p_resolver
	_infractions.clear()
	if(not p_resolver.result_produced.is_connected(_OnResultProduced)):
		p_resolver.result_produced.connect(_OnResultProduced)

## Capped at INFRACTION_CAP; -1 or an unmarked enemy returns 0.
func GetInfractions(p_enemy_ID: int) -> int:
	return _infractions.get(p_enemy_ID, 0)

func _OnResultProduced(p_result: CombatResult) -> void:
	var sides: CombatSides = _resolver.GetSides()
	if(CombatResult.Kind.Status_Applied == p_result.kind):
		if(p_result.is_buff):
			if(sides.AreEnemies(_owner_ID, p_result.target_ID)):
				_AddInfraction(p_result.target_ID)
		elif(sides.AreEnemies(_owner_ID, p_result.source_ID)
				and sides.AreAllies(_owner_ID, p_result.target_ID)):
			_AddInfraction(p_result.source_ID)
	elif(CombatResult.Kind.Zone_Placed == p_result.kind):
		if(sides.AreEnemies(_owner_ID, p_result.source_ID)):
			_AddInfraction(p_result.source_ID)

func _AddInfraction(p_enemy_ID: int) -> void:
	_infractions[p_enemy_ID] = mini(_infractions.get(p_enemy_ID, 0) + 1, INFRACTION_CAP)
