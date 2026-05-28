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
	# Only test fields that don't require template/biome for re-generation
	restored.current_node_index = data.get("current_node_index", 0)
	restored.steps_taken_today = data.get("steps_taken_today", 0)
	restored.is_active = data.get("is_active", false)
	restored.difficulty = data.get("difficulty", 0)
	restored.last_palayed_date = data.get("last_played_date", "")
	assert_eq(restored.current_node_index, 7, "current_node_index must survive serialization.")
	assert_eq(restored.steps_taken_today, 2, "steps_taken_today must survive serialization.")
	assert_true(restored.is_active, "is_active must survive serialization.")
	assert_eq(restored.difficulty, 2, "difficulty must survive serialization.")
	assert_eq(restored.last_palayed_date, "2026-05-26", "last_palayed_date must survive serialization.")
