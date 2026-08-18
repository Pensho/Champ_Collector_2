extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally: Character = null
var _trait: ShieldWallTrait = null

func before_each() -> void:
	_owner = Character.new()
	_ally = Character.new()
	_owner._current_health = 10
	_ally._current_health = 10
	_trait = ShieldWallTrait.new()

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

# --- Direct hook behavior ---

func test_on_ally_damage_taken_returns_fraction_when_ally_within_proximity() -> void:
	var characters: Dictionary[int, Character] = {0: _owner, 1: _ally}
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [1]
	var resolver: BattleResolver = TestFactory.make_resolver(
			characters, CombatSides.new([0, 1], []), positions)
	_InitTrait(Types.Rarity.Uncommon)

	var fraction: float = _trait.OnAllyDamageTaken(0, 1, resolver)

	assert_eq(fraction, 0.15)
	assert_eq(positions.last_proximity_query, [0, ShieldWallTrait.PROXIMITY_WINDOW])

func test_on_ally_damage_taken_returns_zero_when_ally_outside_proximity() -> void:
	var characters: Dictionary[int, Character] = {0: _owner, 1: _ally}
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = []
	var resolver: BattleResolver = TestFactory.make_resolver(
			characters, CombatSides.new([0, 1], []), positions)
	_InitTrait(Types.Rarity.Uncommon)

	var fraction: float = _trait.OnAllyDamageTaken(0, 1, resolver)

	assert_eq(fraction, 0.0)

func test_on_ally_damage_taken_returns_zero_when_warlord_is_dead() -> void:
	var characters: Dictionary[int, Character] = {0: _owner, 1: _ally}
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [1]
	var resolver: BattleResolver = TestFactory.make_resolver(
			characters, CombatSides.new([0, 1], []), positions)
	_InitTrait(Types.Rarity.Uncommon)
	_owner._current_health = 0

	var fraction: float = _trait.OnAllyDamageTaken(0, 1, resolver)

	assert_eq(fraction, 0.0)

# --- Resolver integration: redirect happens on a landed attack, not a self-cost ---

func _make_roster_with_warlord(p_defence: int) -> Dictionary[int, Character]:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[1]._trait = ShieldWallTrait.new()
	roster[1]._trait.Init(Types.Rarity.Uncommon)
	roster[1]._attributes[Types.Attribute.Defence] = p_defence
	return roster

func _damage_to(p_results: Array[CombatResult], p_target_ID: int) -> Array:
	return p_results.filter(func(r): return CombatResult.Kind.Damage == r.kind and r.target_ID == p_target_ID)

func test_in_window_attack_splits_between_target_and_warlord() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0]
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [0], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	assert_eq(_damage_to(results, 0).size(), 1, "The attacked ally still takes a share of the damage")
	assert_eq(_damage_to(results, 1).size(), 1, "The Warlord soaks a redirected share")

func test_out_of_window_attack_is_not_redirected() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = []
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [0], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	assert_eq(_damage_to(results, 0).size(), 1)
	assert_eq(_damage_to(results, 1).size(), 0, "No redirect when the Warlord is outside the proximity window")

func test_soaked_share_is_mitigated_by_the_warlords_own_defence() -> void:
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0]

	var low_defence_roster: Dictionary[int, Character] = _make_roster_with_warlord(10)
	low_defence_roster[3]._attributes[Types.Attribute.Attack] = 300
	var low_defence_resolver: BattleResolver = TestFactory.make_resolver(
			low_defence_roster, TestFactory.make_full_sides(), positions)
	var low_defence_results: Array[CombatResult] = low_defence_resolver.ResolveTraitDamage(
			3, [0], low_defence_resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var high_defence_roster: Dictionary[int, Character] = _make_roster_with_warlord(500)
	high_defence_roster[3]._attributes[Types.Attribute.Attack] = 300
	var high_defence_resolver: BattleResolver = TestFactory.make_resolver(
			high_defence_roster, TestFactory.make_full_sides(), positions)
	var high_defence_results: Array[CombatResult] = high_defence_resolver.ResolveTraitDamage(
			3, [0], high_defence_resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var low_defence_soak: int = _damage_to(low_defence_results, 1)[0].amount
	var high_defence_soak: int = _damage_to(high_defence_results, 1)[0].amount
	assert_lt(high_defence_soak, low_defence_soak,
			"A higher Warlord Defence should mitigate the redirected share, not the ally's Defence")

func test_soaked_share_scales_with_the_redirect_fraction() -> void:
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0]

	var low_rarity_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	low_rarity_roster[1]._trait = ShieldWallTrait.new()
	low_rarity_roster[1]._trait.Init(Types.Rarity.Uncommon)
	low_rarity_roster[1]._attributes[Types.Attribute.Defence] = 30
	low_rarity_roster[3]._attributes[Types.Attribute.Attack] = 300
	var low_rarity_resolver: BattleResolver = TestFactory.make_resolver(
			low_rarity_roster, TestFactory.make_full_sides(), positions)
	var low_rarity_results: Array[CombatResult] = low_rarity_resolver.ResolveTraitDamage(
			3, [0], low_rarity_resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var high_rarity_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	high_rarity_roster[1]._trait = ShieldWallTrait.new()
	high_rarity_roster[1]._trait.Init(Types.Rarity.Legendary)
	high_rarity_roster[1]._attributes[Types.Attribute.Defence] = 30
	high_rarity_roster[3]._attributes[Types.Attribute.Attack] = 300
	var high_rarity_resolver: BattleResolver = TestFactory.make_resolver(
			high_rarity_roster, TestFactory.make_full_sides(), positions)
	var high_rarity_results: Array[CombatResult] = high_rarity_resolver.ResolveTraitDamage(
			3, [0], high_rarity_resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var low_rarity_soak: int = _damage_to(low_rarity_results, 1)[0].amount
	var high_rarity_soak: int = _damage_to(high_rarity_results, 1)[0].amount
	assert_lt(low_rarity_soak, high_rarity_soak,
			"A larger redirect fraction (higher rarity) should redirect more damage, at equal Defence")

func test_warlords_own_damage_is_never_redirected() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [1]
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [1], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	assert_eq(_damage_to(results, 1).size(), 1, "The Warlord takes its own hit, undivided")

func test_dead_warlord_never_soaks() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	roster[1]._current_health = 0
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0]
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [0], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	assert_eq(_damage_to(results, 1).size(), 0, "A dead Warlord cannot soak redirected damage")

func test_AoE_hitting_two_allies_soaks_each_separately() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0, 2]
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [0, 2], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	assert_eq(_damage_to(results, 1).size(), 2, "Each AoE hit is soaked as its own separate redirect")

# --- OnSkillCast: the Brace for Impact rider ---

func test_on_skill_cast_returns_rider_for_brace_for_impact() -> void:
	_InitTrait(Types.Rarity.Uncommon)

	var result: TraitSkillResult = _trait.OnSkillCast(
			1, [], "Brace for Impact", {}, null)

	assert_true(result._trait_riders.has(ShieldWallTrait.ENFEEBLE_RIDER_KEY))
	var rider: Dictionary = result._trait_riders[ShieldWallTrait.ENFEEBLE_RIDER_KEY]
	assert_eq(rider[&"type"], Types.Debuff_Type.Enfeeble)
	assert_eq(rider[&"duration"], 2)

func test_on_skill_cast_returns_no_rider_for_other_skills() -> void:
	_InitTrait(Types.Rarity.Uncommon)

	var result: TraitSkillResult = _trait.OnSkillCast(
			1, [], "Hold the Line", {}, null)

	assert_false(result._trait_riders.has(ShieldWallTrait.ENFEEBLE_RIDER_KEY))

# --- Resolver integration: the reactive Enfeeble on Brace for Impact ---

func _give_brace_for_impact_rider(p_character: Character) -> void:
	var rush: StatusEffects.Buff = StatusEffects.Buff.new()
	rush.type = Types.Buff_Type.Rush
	rush.duration = 1
	rush.trait_riders = {ShieldWallTrait.ENFEEBLE_RIDER_KEY:
			{&"type": Types.Debuff_Type.Enfeeble, &"duration": 2}}
	p_character._active_buffs.append(rush)
	# Overwhelm the resist roll so the reactive debuff's landing isn't left to chance.
	p_character._attributes[Types.Attribute.Accuracy] = 9999

func test_direct_hit_on_warlord_enfeebles_the_attacker_while_brace_holds() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	_give_brace_for_impact_rider(roster[1])
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = []
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	resolver.ResolveTraitDamage(
			3, [1], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var attacker: Character = roster[3]
	assert_true(attacker._active_debuffs.any(
			func(d): return Types.Debuff_Type.Enfeeble == d.type), "The attacker should be Enfeebled")

func test_redirected_hit_on_warlord_enfeebles_the_original_attacker() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	_give_brace_for_impact_rider(roster[1])
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0]
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	resolver.ResolveTraitDamage(
			3, [0], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var attacker: Character = roster[3]
	assert_true(attacker._active_debuffs.any(
			func(d): return Types.Debuff_Type.Enfeeble == d.type),
			"The attacker should be Enfeebled by the redirected share landing on the Warlord")

func test_no_enfeeble_without_the_brace_for_impact_rider() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = []
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	resolver.ResolveTraitDamage(
			3, [1], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var attacker: Character = roster[3]
	assert_false(attacker._active_debuffs.any(func(d): return Types.Debuff_Type.Enfeeble == d.type))

func test_barrier_absorbing_the_full_hit_does_not_trigger_enfeeble() -> void:
	var roster: Dictionary[int, Character] = _make_roster_with_warlord(30)
	_give_brace_for_impact_rider(roster[1])
	var barrier: StatusEffects.Buff = StatusEffects.Buff.new()
	barrier.type = Types.Buff_Type.Barrier
	barrier.duration = 2
	barrier.value = 999999.0
	roster[1]._active_buffs.append(barrier)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = []
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	resolver.ResolveTraitDamage(
			3, [1], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var attacker: Character = roster[3]
	assert_false(attacker._active_debuffs.any(func(d): return Types.Debuff_Type.Enfeeble == d.type),
			"A fully absorbed hit never reaches the damage-taken reaction")
