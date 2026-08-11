extends GutTest

var _trait: TidalCorsairTrait = null

func before_each() -> void:
	_trait = TidalCorsairTrait.new()

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

# --- Stack accumulation ---

func test_boarding_strike_grants_steel_stack() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, null)
	assert_eq(_trait._held_stacks[0], TidalCorsairTrait.Stack_Type.Steel)

func test_saltwater_shot_grants_sea_stack() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Saltwater Shot", {}, null)
	assert_eq(_trait._held_stacks[0], TidalCorsairTrait.Stack_Type.Sea)

func test_stacks_fill_leftmost_empty_slot_first() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, null)
	_trait.OnSkillCast(0, [], "Saltwater Shot", {}, null)
	assert_eq(_trait._held_stacks[0], TidalCorsairTrait.Stack_Type.Steel)
	assert_eq(_trait._held_stacks[1], TidalCorsairTrait.Stack_Type.Sea)

func test_start_of_battle_resets_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, null)
	_trait.StartOfBattle(0, null)
	for stack_type in _trait._held_stacks:
		assert_eq(stack_type, TidalCorsairTrait.Stack_Type.Empty)

# --- Corsair's Reckoning consumption ---

func test_reckoning_applies_damage_bonus_per_steel_stack_scaled_by_rarity() -> void:
	_InitTrait(Types.Rarity.Legendary)  # 60% per Steel stack
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, null)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, null)
	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, null)
	assert_almost_eq(result._damage_multiplier, 1.0 + 2 * 0.60, 0.0001,
		"Two Steel stacks at Legendary should add 2 x 60% damage multiplier")

func test_reckoning_applies_turn_bar_bump_per_sea_stack_scaled_by_rarity() -> void:
	_InitTrait(Types.Rarity.Rare)  # 10% per Sea stack
	_trait.OnSkillCast(0, [], "Saltwater Shot", {}, null)
	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, null)
	assert_almost_eq(result._turn_bar_bump, -0.10, 0.0001,
		"One Sea stack at Rare should bump turn bar by -10%")

func test_reckoning_consumes_all_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, null)
	_trait.OnSkillCast(0, [], "Saltwater Shot", {}, null)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, null)
	for stack_type in _trait._held_stacks:
		assert_eq(stack_type, TidalCorsairTrait.Stack_Type.Empty)
