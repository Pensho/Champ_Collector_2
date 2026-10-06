extends GutTest

const Choice = CombatPreparation.Choice

var _resources: ResourceHandler

func before_each() -> void:
	_resources = ResourceHandler.new()

func after_each() -> void:
	_resources.free()

func test_prepare_is_offered_on_every_combat_node() -> void:
	assert_true(CombatPreparation.IsOffered(Choice.PREPARE, NodeData.Node_Type.FIGHT))
	assert_true(CombatPreparation.IsOffered(Choice.PREPARE, NodeData.Node_Type.BOSS))

func test_bait_is_offered_only_on_boss_nodes() -> void:
	assert_true(CombatPreparation.IsOffered(Choice.BAIT, NodeData.Node_Type.BOSS))
	assert_false(CombatPreparation.IsOffered(Choice.BAIT, NodeData.Node_Type.FIGHT))

func test_nothing_is_offered_on_non_combat_nodes() -> void:
	for node_type: NodeData.Node_Type in [NodeData.Node_Type.REST_STOP, NodeData.Node_Type.HINT,
			NodeData.Node_Type.GAMBLE, NodeData.Node_Type.ESCALATE]:
		assert_false(CombatPreparation.IsOffered(Choice.PREPARE, node_type))
		assert_false(CombatPreparation.IsOffered(Choice.BAIT, node_type))

func test_toggle_selects_at_most_one_choice() -> void:
	assert_eq(CombatPreparation.Toggle(Choice.NONE, Choice.PREPARE), Choice.PREPARE)
	assert_eq(CombatPreparation.Toggle(Choice.PREPARE, Choice.BAIT), Choice.BAIT,
			"Picking Bait should replace Prepare")
	assert_eq(CombatPreparation.Toggle(Choice.BAIT, Choice.BAIT), Choice.NONE,
			"Pressing the selected choice again should clear it")

func test_only_bait_raises_difficulty() -> void:
	assert_eq(CombatPreparation.DifficultyIncrease(Choice.BAIT), GameBalance.ADVENTURE_BAIT_DIFFICULTY_INCREASE)
	assert_eq(CombatPreparation.DifficultyIncrease(Choice.PREPARE), 0)
	assert_eq(CombatPreparation.DifficultyIncrease(Choice.NONE), 0)

func test_only_prepare_grants_a_turn_bar_head_start() -> void:
	assert_eq(CombatPreparation.StartingTurnBarFraction(Choice.PREPARE),
			GameBalance.ADVENTURE_PREPARE_TURN_BAR_FRACTION)
	assert_eq(CombatPreparation.StartingTurnBarFraction(Choice.BAIT), 0.0)
	assert_eq(CombatPreparation.StartingTurnBarFraction(Choice.NONE), 0.0)

func test_purchase_spends_the_choice_cost() -> void:
	_resources.AddSupplies(15)
	assert_eq(CombatPreparation.Purchase(Choice.BAIT, _resources), Choice.BAIT)
	assert_eq(_resources.GetSupplies(), 15 - GameBalance.ADVENTURE_BAIT_COST)

func test_purchase_without_enough_supplies_buys_nothing() -> void:
	_resources.AddSupplies(GameBalance.ADVENTURE_PREPARE_COST - 1)
	assert_eq(CombatPreparation.Purchase(Choice.PREPARE, _resources), Choice.NONE)
	assert_eq(_resources.GetSupplies(), GameBalance.ADVENTURE_PREPARE_COST - 1)

func test_purchase_of_none_is_free() -> void:
	_resources.AddSupplies(5)
	assert_eq(CombatPreparation.Purchase(Choice.NONE, _resources), Choice.NONE)
	assert_eq(_resources.GetSupplies(), 5)

func test_refund_returns_the_purchase_cost() -> void:
	_resources.AddSupplies(10)
	var bought: Choice = CombatPreparation.Purchase(Choice.PREPARE, _resources)
	CombatPreparation.Refund(bought, _resources)
	assert_eq(_resources.GetSupplies(), 10)
