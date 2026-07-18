extends GutTest

var _trait: TidalCorsairTrait = null

func before_each() -> void:
	_trait = TidalCorsairTrait.new()

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

# --- Rarity tables ---

func test_damage_per_steel_stack_uncommon() -> void:
	assert_eq(TidalCorsairTrait.DAMAGE_PER_STEEL_STACK.get(Types.Rarity.Uncommon, 0.0), 0.45)

func test_damage_per_steel_stack_rare() -> void:
	assert_eq(TidalCorsairTrait.DAMAGE_PER_STEEL_STACK.get(Types.Rarity.Rare, 0.0), 0.50)

func test_damage_per_steel_stack_epic() -> void:
	assert_eq(TidalCorsairTrait.DAMAGE_PER_STEEL_STACK.get(Types.Rarity.Epic, 0.0), 0.55)

func test_damage_per_steel_stack_legendary() -> void:
	assert_eq(TidalCorsairTrait.DAMAGE_PER_STEEL_STACK.get(Types.Rarity.Legendary, 0.0), 0.60)

func test_turn_bar_per_sea_stack_uncommon() -> void:
	assert_eq(TidalCorsairTrait.TURN_BAR_PER_SEA_STACK.get(Types.Rarity.Uncommon, 0.0), 0.08)

func test_turn_bar_per_sea_stack_rare() -> void:
	assert_eq(TidalCorsairTrait.TURN_BAR_PER_SEA_STACK.get(Types.Rarity.Rare, 0.0), 0.10)

func test_turn_bar_per_sea_stack_epic() -> void:
	assert_eq(TidalCorsairTrait.TURN_BAR_PER_SEA_STACK.get(Types.Rarity.Epic, 0.0), 0.12)

func test_turn_bar_per_sea_stack_legendary() -> void:
	assert_eq(TidalCorsairTrait.TURN_BAR_PER_SEA_STACK.get(Types.Rarity.Legendary, 0.0), 0.14)

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
	_trait.StartOfBattle()
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

# --- Stack descriptions ---

func test_steel_description_reflects_rarity_scaled_damage() -> void:
	_InitTrait(Types.Rarity.Legendary)  # 60% per Steel stack
	assert_eq(_trait._steel_description._body,
		"Consumed by Corsair's Reckoning for +60% damage.")

func test_sea_description_reflects_rarity_scaled_turn_bar() -> void:
	_InitTrait(Types.Rarity.Rare)  # 10% per Sea stack
	assert_eq(_trait._sea_description._body,
		"Consumed by Corsair's Reckoning for -10% target turn bar.")

func test_reckoning_consumes_all_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, null)
	_trait.OnSkillCast(0, [], "Saltwater Shot", {}, null)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, null)
	for stack_type in _trait._held_stacks:
		assert_eq(stack_type, TidalCorsairTrait.Stack_Type.Empty)
