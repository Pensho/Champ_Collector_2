extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _trait: TidalCorsairTrait = null
var _characters: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_trait = TidalCorsairTrait.new()
	_characters.assign(TestFactory.make_full_roster())
	_characters[0]._trait = _trait
	_resolver = TestFactory.make_resolver(_characters, TestFactory.make_full_sides())

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

func _fill_hand(p_steel: int, p_sea: int) -> void:
	for i in p_steel:
		_trait.OnSkillCast(0, [], "Boarding Strike", {}, _resolver)
	for i in p_sea:
		_trait.OnSkillCast(0, [], "Saltwater Shot", {}, _resolver)

# --- Stack accumulation ---

func test_boarding_strike_grants_steel_stack() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, _resolver)
	assert_eq(_trait._held_stacks[0], TidalCorsairTrait.Stack_Type.Steel)

func test_saltwater_shot_grants_sea_stack() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Saltwater Shot", {}, _resolver)
	assert_eq(_trait._held_stacks[0], TidalCorsairTrait.Stack_Type.Sea)

func test_stacks_fill_leftmost_empty_slot_first() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, _resolver)
	_trait.OnSkillCast(0, [], "Saltwater Shot", {}, _resolver)
	assert_eq(_trait._held_stacks[0], TidalCorsairTrait.Stack_Type.Steel)
	assert_eq(_trait._held_stacks[1], TidalCorsairTrait.Stack_Type.Sea)

func test_start_of_battle_resets_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Boarding Strike", {}, _resolver)
	_trait.StartOfBattle(0, _resolver)
	for stack_type in _trait._held_stacks:
		assert_eq(stack_type, TidalCorsairTrait.Stack_Type.Empty)

func test_reckoning_consumes_all_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	_fill_hand(1, 1)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	for stack_type in _trait._held_stacks:
		assert_eq(stack_type, TidalCorsairTrait.Stack_Type.Empty)

# --- Broadside (Steel only) ---

func test_broadside_applies_damage_bonus_per_steel_stack_scaled_by_rarity() -> void:
	_InitTrait(Types.Rarity.Legendary)  # 60% per Steel stack
	_fill_hand(2, 0)
	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	assert_almost_eq(result._damage_multiplier, 1.0 + 2 * 0.60, 0.0001,
		"Two Steel stacks at Legendary should add 2 x 60% damage multiplier")

func test_broadside_raises_no_deck() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fill_hand(3, 0)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	assert_true(_resolver.GetZoneResolver().GetZones().is_empty(), "A pure Steel hand must raise no deck")

# --- Bring Her Alongside (Sea only) ---

func test_sea_only_raises_the_deck_at_two_charges_per_sea() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fill_hand(0, 2)
	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	assert_almost_eq(result._damage_multiplier, 1.0, 0.0001, "A pure Sea hand adds no damage bonus")
	var zones: Dictionary[int, Zone] = _resolver.GetZoneResolver().GetZones()
	assert_eq(zones.size(), 1)
	assert_eq(zones.values()[0]._charges, 4)

func test_sea_only_resupplies_rather_than_raising_a_second_deck() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fill_hand(0, 1)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	_fill_hand(0, 1)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	var zones: Dictionary[int, Zone] = _resolver.GetZoneResolver().GetZones()
	assert_eq(zones.size(), 1, "A second Sea-only Reckoning should resupply, not raise a second deck")
	assert_eq(zones.values()[0]._charges, 4)

func test_sea_only_with_all_sections_occupied_raises_no_deck() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var zone_resolver: ZoneResolver = _resolver.GetZoneResolver()
	for zone_ID in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
		TestFactory.place_zone(_resolver, zone_ID, 1, TestFactory.make_zone_effect(1), Types.Skill_Target.ZoneAlly)
	_fill_hand(0, 2)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	for zone_ID in zone_resolver.GetZones():
		assert_eq(zone_resolver.GetZones()[zone_ID]._owner_ID, 1,
			"Every occupied section must stay as it was; the Corsair raises nothing")

# --- Boarding Party (mixed) ---

func test_mixed_hand_adds_no_damage_bonus() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fill_hand(1, 1)
	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	assert_almost_eq(result._damage_multiplier, 1.0, 0.0001,
		"A mixed hand deals Steel damage at the skill's own base rate")

func test_mixed_hand_raises_the_deck_at_one_charge_per_sea_capped_at_two() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fill_hand(1, 2)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	var zones: Dictionary[int, Zone] = _resolver.GetZoneResolver().GetZones()
	assert_eq(zones.size(), 1)
	assert_eq(zones.values()[0]._charges, 2)

func test_mixed_hand_grants_slipstream_and_empower_to_other_living_allies() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fill_hand(1, 1)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	for ally_ID in [1, 2]:
		var buff_types: Array = _characters[ally_ID]._active_buffs.map(func(b): return b.type)
		assert_true(buff_types.has(Types.Buff_Type.Slipstream), "Ally %d should gain Slipstream" % ally_ID)
		assert_true(buff_types.has(Types.Buff_Type.Empower), "Ally %d should gain Empower" % ally_ID)

func test_mixed_hand_does_not_buff_the_corsair_itself() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_fill_hand(1, 1)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	assert_true(_characters[0]._active_buffs.is_empty(), "The Corsair itself must not receive the crew buffs")

func test_mixed_hand_with_all_sections_occupied_still_grants_crew_buffs() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var zone_resolver: ZoneResolver = _resolver.GetZoneResolver()
	for zone_ID in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
		TestFactory.place_zone(_resolver, zone_ID, 1, TestFactory.make_zone_effect(1), Types.Skill_Target.ZoneAlly)
	_fill_hand(1, 1)
	_trait.OnSkillCast(0, [], "Corsairs Reckoning", {}, _resolver)
	var buff_types: Array = _characters[1]._active_buffs.map(func(b): return b.type)
	assert_true(buff_types.has(Types.Buff_Type.Slipstream),
		"The crew buff is independent of whether the deck could be raised")
