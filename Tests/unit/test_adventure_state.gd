extends GutTest

var _state: AdventureState

func before_each() -> void:
	_state = AdventureState.new()
	_state.steps_taken_today = 0

func test_supply_cost_tier_1() -> void:
	_state.steps_taken_today = 0
	var cost: int = _state.GetNodeSupplyCost()
	assert_eq(cost, GameBalance.ADVENTURE_ENERGY_COST_PER_TIER,
		"First tier should cost ADVENTURE_ENERGY_COST_PER_TIER.")

func test_supply_cost_tier_2() -> void:
	_state.steps_taken_today = GameBalance.ADVENTURE_DAILY_TIER_THRESHOLD
	var cost: int = _state.GetNodeSupplyCost()
	assert_eq(cost, GameBalance.ADVENTURE_ENERGY_COST_PER_TIER * 2,
		"Second tier should cost 2x ADVENTURE_ENERGY_COST_PER_TIER.")

func test_supply_cost_tier_3() -> void:
	_state.steps_taken_today = GameBalance.ADVENTURE_DAILY_TIER_THRESHOLD * 2
	var cost: int = _state.GetNodeSupplyCost()
	assert_eq(cost, GameBalance.ADVENTURE_ENERGY_COST_PER_TIER * 3,
		"Third tier should cost 3x ADVENTURE_ENERGY_COST_PER_TIER.")

func test_daily_reset() -> void:
	_state.steps_taken_today = 4
	# Set last_palayed_date to yesterday
	var yesterday: Dictionary = Time.get_datetime_dict_from_system()
	yesterday["day"] -= 1
	_state.last_palayed_date = "%04d-%02d-%02d" % [yesterday["year"], yesterday["month"], yesterday["day"]]
	_state.CheckDailyActivity()
	assert_eq(_state.steps_taken_today, 0, "Steps should reset when a new day is detected.")

func test_no_reset_same_day() -> void:
	_state.steps_taken_today = 3
	_state.last_palayed_date = Time.get_date_string_from_system()
	_state.CheckDailyActivity()
	assert_eq(_state.steps_taken_today, 3, "Steps should not reset on the same day.")

func test_serialize_roundtrip() -> void:
	_state.current_node_index = 7
	_state.steps_taken_today = 2
	_state.is_active = true
	_state.difficulty = 2
	_state.last_palayed_date = "2026-05-26"
	var data: Dictionary = _state.Serialize()
	var restored: AdventureState = AdventureState.new()
	restored.Deserialize(data)
	# is_active is intentionally not asserted: Deserialize forces it false when
	# no template/biome paths are resolvable (correct behaviour for a test state).
	assert_eq(restored.current_node_index, 7, "current_node_index must survive serialization.")
	assert_eq(restored.steps_taken_today, 2, "steps_taken_today must survive serialization.")
	assert_eq(restored.difficulty, 2, "difficulty must survive serialization.")
	assert_eq(restored.last_palayed_date, "2026-05-26", "last_palayed_date must survive serialization.")


# --- Node completion (guards the victory-marks-node-complete bug fix) ---

func test_victory_marks_only_current_node_complete() -> void:
	_state.current_node_index = 2
	var node_1 := NodeData.new(); node_1.index = 1
	var node_2 := NodeData.new(); node_2.index = 2
	var node_3 := NodeData.new(); node_3.index = 3
	var typed_nodes: Array[NodeData] = []
	typed_nodes.assign([node_1, node_2, node_3])
	_state.nodes = typed_nodes

	_state.MarkCurrentNodeComplete()

	assert_false(node_1.is_complete, "Non-current node must not be marked complete")
	assert_true(node_2.is_complete, "Node matching current_node_index must be marked complete")
	assert_false(node_3.is_complete, "Non-current node must not be marked complete")


func test_nodes_start_incomplete() -> void:
	var node := NodeData.new()
	node.index = 1
	assert_false(node.is_complete, "Nodes must start as incomplete so a loss does not count as a win")


# --- Progressive difficulty scaling ---

func test_scaled_difficulty_start() -> void:
	assert_eq(AdventureState.CalculateScaledDifficulty(1, 0, 9), 1,
		"No nodes completed: difficulty unchanged.")

func test_scaled_difficulty_first_third() -> void:
	assert_eq(AdventureState.CalculateScaledDifficulty(1, 3, 9), 2,
		"One third completed: difficulty +1.")

func test_scaled_difficulty_second_third() -> void:
	assert_eq(AdventureState.CalculateScaledDifficulty(1, 6, 9), 3,
		"Two thirds completed: difficulty +2.")

func test_scaled_difficulty_caps_at_two_tiers() -> void:
	assert_eq(AdventureState.CalculateScaledDifficulty(1, 9, 9), 3,
		"All nodes completed: capped at +2 tiers.")

func test_scaled_difficulty_empty_adventure() -> void:
	assert_eq(AdventureState.CalculateScaledDifficulty(2, 0, 0), 2,
		"Zero total nodes: returns base difficulty unchanged.")


# --- Adventure-spanning effects ---

func test_add_adventure_buff() -> void:
	_state.AddAdventureBuff(Types.Buff_Type.Empower, 3)
	assert_eq(_state.active_buffs[Types.Buff_Type.Empower], 3,
		"AddAdventureBuff should store the combat count for the buff type.")

func test_add_adventure_debuff() -> void:
	_state.AddAdventureDebuff(Types.Debuff_Type.Burning, 2)
	assert_eq(_state.active_debuffs[Types.Debuff_Type.Burning], 2,
		"AddAdventureDebuff should store the combat count for the debuff type.")

func test_decrement_adventure_effects() -> void:
	_state.AddAdventureBuff(Types.Buff_Type.Empower, 2)
	_state.AddAdventureDebuff(Types.Debuff_Type.Burning, 2)

	_state.DecrementAdventureEffects()
	assert_eq(_state.active_buffs[Types.Buff_Type.Empower], 1, "Buff should decrement by 1.")
	assert_eq(_state.active_debuffs[Types.Debuff_Type.Burning], 1, "Debuff should decrement by 1.")

	_state.DecrementAdventureEffects()
	assert_false(_state.active_buffs.has(Types.Buff_Type.Empower), "Buff should be erased once it reaches 0.")
	assert_false(_state.active_debuffs.has(Types.Debuff_Type.Burning), "Debuff should be erased once it reaches 0.")

func test_permanent_adventure_buff_never_decrements() -> void:
	_state.AddAdventureBuff(Types.Buff_Type.Fortify, GameBalance.ADVENTURE_PERMANENT_EFFECT)
	for i in 5:
		_state.DecrementAdventureEffects()
	assert_eq(_state.active_buffs[Types.Buff_Type.Fortify], GameBalance.ADVENTURE_PERMANENT_EFFECT,
		"A permanent-sentinel buff must never decrement.")

func test_adventure_effects_serialize_roundtrip() -> void:
	_state.AddAdventureBuff(Types.Buff_Type.Empower, 3)
	_state.AddAdventureDebuff(Types.Debuff_Type.Burning, 2)
	var data: Dictionary = _state.Serialize()
	var restored: AdventureState = AdventureState.new()
	restored.Deserialize(data)
	assert_eq(restored.active_buffs[Types.Buff_Type.Empower], 3, "active_buffs must survive serialization.")
	assert_eq(restored.active_debuffs[Types.Debuff_Type.Burning], 2, "active_debuffs must survive serialization.")
