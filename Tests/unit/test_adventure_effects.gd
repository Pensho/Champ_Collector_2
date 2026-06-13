extends GutTest

var _state: AdventureState

func before_each() -> void:
	_state = AdventureState.new()

func test_buff_decays_over_four_combats() -> void:
	_state.AddAdventureBuff(Types.Buff_Type.Empower, 4)

	var expected: Array[int] = [3, 2, 1]
	for combats_remaining in expected:
		_state.DecrementAdventureEffects()
		assert_eq(_state.active_buffs[Types.Buff_Type.Empower], combats_remaining,
			"Buff should decrement by 1 per combat.")

	_state.DecrementAdventureEffects()
	assert_false(_state.active_buffs.has(Types.Buff_Type.Empower),
		"Buff should be gone after its full duration has elapsed.")

func test_debuff_decays_over_two_combats() -> void:
	_state.AddAdventureDebuff(Types.Debuff_Type.Enfeeble, 2)

	_state.DecrementAdventureEffects()
	assert_eq(_state.active_debuffs[Types.Debuff_Type.Enfeeble], 1,
		"Debuff should decrement by 1 per combat.")

	_state.DecrementAdventureEffects()
	assert_false(_state.active_debuffs.has(Types.Debuff_Type.Enfeeble),
		"Debuff should be gone after its full duration has elapsed.")
