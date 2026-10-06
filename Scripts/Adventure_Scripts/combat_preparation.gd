class_name CombatPreparation

## The optional Supplies purchase made before entering an adventure combat node.
## The player picks at most one choice per combat.

enum Choice { NONE, PREPARE, BAIT }

const ARGUMENT_KEY: String = "Combat_Preparation"

static func IsOffered(p_choice: Choice, p_node_type: NodeData.Node_Type) -> bool:
	match p_choice:
		Choice.PREPARE:
			return p_node_type == NodeData.Node_Type.FIGHT or p_node_type == NodeData.Node_Type.BOSS
		Choice.BAIT:
			return p_node_type == NodeData.Node_Type.BOSS
		_:
			return false

static func Cost(p_choice: Choice) -> int:
	match p_choice:
		Choice.PREPARE:
			return GameBalance.ADVENTURE_PREPARE_COST
		Choice.BAIT:
			return GameBalance.ADVENTURE_BAIT_COST
		_:
			return 0

## Pressing the selected choice again clears it; pressing the other one replaces it.
static func Toggle(p_current: Choice, p_pressed: Choice) -> Choice:
	return Choice.NONE if p_current == p_pressed else p_pressed

static func DifficultyIncrease(p_choice: Choice) -> int:
	return GameBalance.ADVENTURE_BAIT_DIFFICULTY_INCREASE if p_choice == Choice.BAIT else 0

static func StartingTurnBarFraction(p_choice: Choice) -> float:
	if p_choice == Choice.PREPARE:
		return GameBalance.ADVENTURE_PREPARE_TURN_BAR_FRACTION
	return 0.0

## Returns the choice actually bought: NONE when the player cannot afford it.
static func Purchase(p_choice: Choice, p_resources: ResourceHandler) -> Choice:
	if p_choice == Choice.NONE or not p_resources.SpendSupplies(Cost(p_choice)):
		return Choice.NONE
	return p_choice

static func Refund(p_choice: Choice, p_resources: ResourceHandler) -> void:
	if p_choice != Choice.NONE:
		p_resources.AddSupplies(Cost(p_choice))
