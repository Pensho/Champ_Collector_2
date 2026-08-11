extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const CARAVAN_CADENCE_PATH: String = "res://Data/Character_Traits/Grafts/Caravan_Cadence_Graft.tres"
const GRAVITIC_ROT_PATH: String = "res://Data/Character_Traits/Grafts/Gravitic_Rot_Graft.tres"
const CONTAGION_BOND_PATH: String = "res://Data/Character_Traits/Grafts/Contagion_Bond_Graft.tres"

func _make_caravan_cadence(p_rarity: Types.Rarity) -> CaravanCadenceGraft:
	var graft: CaravanCadenceGraft = load(CARAVAN_CADENCE_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_gravitic_rot(p_rarity: Types.Rarity) -> GraviticRotGraft:
	var graft: GraviticRotGraft = load(GRAVITIC_ROT_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_contagion_bond(p_rarity: Types.Rarity) -> ContagionBondGraft:
	var graft: ContagionBondGraft = load(CONTAGION_BOND_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _bumps(p_batch: Array[CombatResult]) -> Array[CombatResult]:
	return p_batch.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump)

# --- Caravan Cadence ---

func test_caravan_cadence_blocks_forward_turn_bar_bumps() -> void:
	var graft: CaravanCadenceGraft = _make_caravan_cadence(Types.Rarity.Uncommon)
	assert_true(graft.BlocksForwardTurnBarBump(0))

func test_caravan_cadence_forward_block_suppresses_a_bump_through_the_resolver() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Uncommon
	character.ApplyGraft(load(CARAVAN_CADENCE_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, CombatSides.new([0], []))

	resolver.BumpTurnBar(0, 0.2)

	assert_eq(_bumps(resolver._batch).size(), 0, "Caravan Cadence must block a forward push on itself")

func test_caravan_cadence_can_still_be_pushed_backward() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Uncommon
	character.ApplyGraft(load(CARAVAN_CADENCE_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, CombatSides.new([0], []))

	resolver.BumpTurnBar(0, -0.2)

	assert_eq(_bumps(resolver._batch).size(), 1, "Caravan Cadence's forward-only block must allow a pullback")

func test_caravan_cadence_pushes_the_first_returned_ally() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.behind_ordered_IDs = [2, 1]
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: CaravanCadenceGraft = _make_caravan_cadence(Types.Rarity.Uncommon)

	graft.StartOfTurn(0, resolver)

	var bumps: Array[CombatResult] = _bumps(resolver._batch)
	assert_eq(bumps.size(), 1, "Only the first (furthest-behind) ally should be pushed")
	assert_eq(bumps[0].target_ID, 2)
	assert_almost_eq(bumps[0].fraction, CaravanCadenceGraft.TURN_BAR_PUSH_PER_RARITY[Types.Rarity.Uncommon], 0.0001)

func test_caravan_cadence_does_nothing_with_no_allies_behind() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.behind_ordered_IDs = []
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: CaravanCadenceGraft = _make_caravan_cadence(Types.Rarity.Uncommon)

	graft.StartOfTurn(0, resolver)

	assert_eq(_bumps(resolver._batch).size(), 0)

# --- Gravitic Rot ---

func test_gravitic_rot_reach_threshold_matches_the_rear_window_across_rarities() -> void:
	for rarity: Types.Rarity in GraviticRotGraft.TURN_BAR_DRAIN_PER_RARITY:
		assert_eq(GraviticRotGraft.GetReachThreshold(rarity), GraviticRotGraft.REAR_PROXIMITY,
				"The rear window doesn't scale by rarity, matching Plan/Foresight's flat-window siblings")

func test_gravitic_rot_drains_every_enemy_behind_and_ignores_allies() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.behind_IDs = [1, 3, 4]  # 1 is an ally, 3/4 are enemies
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: GraviticRotGraft = _make_gravitic_rot(Types.Rarity.Uncommon)

	graft.StartOfTurn(0, resolver)

	var bumps: Array[CombatResult] = _bumps(resolver._batch)
	var bumped_targets: Array[int] = []
	for bump in bumps:
		bumped_targets.append(bump.target_ID)
	bumped_targets.sort()
	assert_eq(bumped_targets, [3, 4], "Only the enemies behind should be drained, not the ally")
	for bump in bumps:
		assert_almost_eq(bump.fraction, -GraviticRotGraft.TURN_BAR_DRAIN_PER_RARITY[Types.Rarity.Uncommon], 0.0001)

func test_gravitic_rot_queries_the_20_percent_rear_window() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: GraviticRotGraft = _make_gravitic_rot(Types.Rarity.Uncommon)

	graft.StartOfTurn(0, resolver)

	assert_eq(positions.last_behind_query, [0, 0.20])

# --- Contagion Bond ---

func test_contagion_bond_reach_threshold_matches_the_width_table() -> void:
	for rarity: Types.Rarity in ContagionBondGraft.CONTAGION_WIDTH_PER_RARITY:
		assert_eq(ContagionBondGraft.GetReachThreshold(rarity), ContagionBondGraft.CONTAGION_WIDTH_PER_RARITY[rarity],
				"GetReachThreshold should surface the same per-rarity width the turn bar overlay reads")

func test_contagion_bond_copies_a_gained_buff_to_the_first_ally_returned() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_ordered_IDs = [4, 1]  # 4 is an enemy (skipped), 1 is an ally
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: ContagionBondGraft = _make_contagion_bond(Types.Rarity.Uncommon)
	var gained: StatusEffects.Buff = StatusEffects.Buff.new()
	gained.type = Types.Buff_Type.Empower
	gained.value = 0.3

	graft.OnBuffGained(0, gained, resolver)

	assert_eq(roster[1]._active_buffs.size(), 1, "The nearest ally, not the enemy, should receive the copy")
	assert_eq(roster[1]._active_buffs[0].type, Types.Buff_Type.Empower)
	assert_eq(roster[1]._active_buffs[0].duration, 1)
	assert_true(roster[4]._active_buffs.is_empty())

func test_contagion_bond_copies_a_received_debuff_to_the_first_enemy_returned() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	roster[4]._attributes[Types.Attribute.Resistance] = 1
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_ordered_IDs = [1, 4]  # 1 is an ally (skipped), 4 is an enemy
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: ContagionBondGraft = _make_contagion_bond(Types.Rarity.Uncommon)
	var landed: StatusEffects.Debuff = StatusEffects.Debuff.new()
	landed.type = Types.Debuff_Type.Enfeeble

	graft.OnDebuffReceived(0, landed, resolver)

	assert_eq(roster[4]._active_debuffs.size(), 1, "The nearest enemy, not the ally, should catch the copy")
	assert_eq(roster[4]._active_debuffs[0].type, Types.Debuff_Type.Enfeeble)
	assert_eq(roster[4]._active_debuffs[0].duration, 1)
	assert_eq(roster[4]._active_debuffs[0].source_ID, 0)
	assert_true(roster[1]._active_debuffs.is_empty())

func test_contagion_bond_debuff_copy_can_be_resisted() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.Accuracy] = 1
	roster[4]._attributes[Types.Attribute.Resistance] = 1000
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_ordered_IDs = [4]
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: ContagionBondGraft = _make_contagion_bond(Types.Rarity.Uncommon)
	var landed: StatusEffects.Debuff = StatusEffects.Debuff.new()
	landed.type = Types.Debuff_Type.Enfeeble

	graft.OnDebuffReceived(0, landed, resolver)

	assert_true(roster[4]._active_debuffs.is_empty(), "A dominant Resistance should resist the copy")

func test_contagion_bond_mutual_carriers_do_not_recurse_infinitely() -> void:
	# Two Contagion Bond carriers standing within each other's width: a debuff copy
	# bouncing 0 -> 4 -> 0 must stop at the reentrancy guard, not loop forever.
	var roster: Dictionary = TestFactory.make_full_roster()
	for id in [0, 4]:
		roster[id]._attributes[Types.Attribute.Accuracy] = 1000
		roster[id]._attributes[Types.Attribute.Resistance] = 1
		roster[id]._rarity = Types.Rarity.Uncommon
		roster[id].ApplyGraft(load(CONTAGION_BOND_PATH))
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_ordered_by_owner = {0: [4], 4: [0]}
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var initial: StatusEffects.Debuff = StatusEffects.Debuff.new()
	initial.type = Types.Debuff_Type.Enfeeble
	initial.source_ID = 4

	resolver.GetStatusResolver().ApplyDebuff(0, initial)

	assert_eq(roster[0]._active_debuffs.size(), 1, "The bounce-back copy should refresh, not stack, on the origin")
	assert_eq(roster[4]._active_debuffs.size(), 1, "Exactly one copy should land on the mutual partner")
	assert_false((roster[0]._trait as ContagionBondGraft)._relaying, "The guard must be cleared after the chain unwinds")
	assert_false((roster[4]._trait as ContagionBondGraft)._relaying, "The guard must be cleared after the chain unwinds")

func test_contagion_bond_width_queried_matches_rarity() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: ContagionBondGraft = _make_contagion_bond(Types.Rarity.Epic)
	var gained: StatusEffects.Buff = StatusEffects.Buff.new()
	gained.type = Types.Buff_Type.Empower

	graft.OnBuffGained(0, gained, resolver)

	assert_eq(positions.last_proximity_ordered_query, [0, 0.10])
