class_name GraviticRotGraft extends GraftEffect

const TURN_BAR_DRAIN_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.05,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.07,
	Types.Rarity.Legendary: 0.08,
}

const REAR_PROXIMITY: float = 0.20
const SPEED_DRAWBACK: float = -0.10

var _drain: float = 0.0

static func GetReachThreshold(_p_rarity: Types.Rarity) -> float:
	return REAR_PROXIMITY

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_drain = TURN_BAR_DRAIN_PER_RARITY.get(p_rarity, 0.0)
	_title = "Gravitic Rot"
	_body = ("At the start of its turn, every enemy within "
			+ str(int(REAR_PROXIMITY * 100)) + "% behind on the turn bar loses "
			+ str(int(_drain * 100)) + "% turn bar. Losing "
			+ str(int(-SPEED_DRAWBACK * 100)) + "% Speed.")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var behind: Array[int] = p_resolver.GetTurnPositions().GetCharactersBehindBy(
			p_owner_ID, REAR_PROXIMITY)
	for id in behind:
		var targets: Array[int] = p_resolver.FindSkillTargets(
				id, p_owner_ID, Types.Skill_Target.Single_Enemy)
		if(targets.has(id)):
			p_resolver.BumpTurnBar(id, -_drain, p_owner_ID)

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Speed: SPEED_DRAWBACK}
