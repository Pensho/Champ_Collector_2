extends GutTest

## The Relics built on the Echo, zone, and reagent plumbing: The Long Furrow, Draught-Fed
## Edge, Threefold Bite, and Lantern of the Standing Ward. Each Relic effect is exercised at
## two rarity steps, plus its drawback.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _equipped_IDs: Array[int] = []

func after_each() -> void:
	for id in _equipped_IDs:
		if(main.GetInstance()._item_collection._items.has(id)):
			main.GetInstance()._item_collection._items[id].free()
			main.GetInstance()._item_collection._items.erase(id)
	_equipped_IDs.clear()

## Puts p_relic_effect on p_character through the real equipment path, so it reaches the
## character via Character.HookSources() exactly as a worn Relic does in a battle.
func _equip_relic(p_character: Character, p_slot: Types.Slot, p_relic_effect: RelicEffect) -> void:
	var equipment: Equipment = Equipment.new()
	equipment._slot = p_slot
	equipment._relic_effect = p_relic_effect
	var id: int = main.GetInstance()._item_collection.CreateNextInstanceID()
	main.GetInstance()._item_collection._items[id] = equipment
	p_character._held_items[p_slot] = id
	_equipped_IDs.append(id)

func _damage_results_against(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind and p_target_ID == r.target_ID)

func _strike_skill(p_name: String) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = p_name
	skill.target = Types.Skill_Target.Single_Enemy
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	skill.effects = [damage]
	return skill

# --- The Long Furrow ---

func _make_long_furrow_setup(p_rarity: Types.Rarity, p_owner_section: int, p_target_section: int) -> Dictionary:
	var caster: Character = TestFactory.make_character()
	caster._current_health = 10
	var relic: TheLongFurrowRelic = TheLongFurrowRelic.new()
	relic.Init(p_rarity)
	caster._trait = relic
	caster._skills = [_strike_skill("Rending Charge")]
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var fake_positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	fake_positions.sections_by_character = {0: p_owner_section, 1: p_target_section}
	var resolver: BattleResolver = TestFactory.make_resolver(
			characters, CombatSides.new([0], [1]), fake_positions)
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	return {"relic": relic, "resolver": resolver}

func test_long_furrow_echoes_rending_charge_at_span_four_or_five_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.25], [Types.Rarity.Legendary, 0.55]]:
		var setup: Dictionary = _make_long_furrow_setup(rarity_and_expected[0], 0, 3)  # span 4
		var resolver: BattleResolver = setup["resolver"]

		var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
		var damage_results: Array[CombatResult] = _damage_results_against(results, 1)

		assert_eq(damage_results.size(), 2,
			"Rarity %s at span 4 should Echo once" % Types.RarityName(rarity_and_expected[0]))
		assert_lt(damage_results[1].amount, damage_results[0].amount,
			"The Echo should deal less than the base cast")
		var buckets: Dictionary[StringName, float] = damage_results[1].combined_damage_modifier.Buckets()
		assert_almost_eq(buckets.get(&"Rending Charge (repeat)", 0.0), rarity_and_expected[1] - 1.0, 0.0001,
			"Rarity %s should Echo at its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_long_furrow_echoes_at_span_five_too() -> void:
	var setup: Dictionary = _make_long_furrow_setup(Types.Rarity.Epic, 0, 4)  # span 5
	var resolver: BattleResolver = setup["resolver"]

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	assert_eq(_damage_results_against(results, 1).size(), 2)

func test_long_furrow_does_not_echo_at_span_three() -> void:
	var setup: Dictionary = _make_long_furrow_setup(Types.Rarity.Epic, 0, 2)  # span 3
	var resolver: BattleResolver = setup["resolver"]

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	assert_eq(_damage_results_against(results, 1).size(), 1,
		"A span outside 4-5 should not Echo")

## Two enablers on the same cast combine into one cascade of two Echoes instead of two
## separate one-Echo cascades.
func test_long_furrow_combines_with_borrowed_time_into_one_two_echo_cascade() -> void:
	var setup: Dictionary = _make_long_furrow_setup(Types.Rarity.Common, 0, 3)  # span 4
	var resolver: BattleResolver = setup["resolver"]
	var caster: Character = resolver.GetCharacters()[0]
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Borrowed_Time
	buff.duration = 1
	buff.value = 0.4
	resolver.GetStatusResolver().ApplyBuff(0, buff)

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var markers: Array[CombatResult] = results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Cascade_Triggered == r.kind)
	assert_eq(markers.size(), 2,
		"The Long Furrow and Borrowed Time should both enable, combining into one two-Echo cascade")
	assert_eq(_damage_results_against(results, 1).size(), 3,
		"The base cast plus both enablers' Echoes should each deal damage")
	assert_true(caster._active_buffs.all(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Borrowed_Time != b.type),
		"Borrowed Time should be consumed once it enables")

func test_long_furrow_suppresses_critical_hits_on_rending_charge_only() -> void:
	var relic: TheLongFurrowRelic = TheLongFurrowRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_true(relic.SuppressesOwnCriticalHit(0, "Rending Charge"),
		"Rending Charge should never critically hit while The Long Furrow is worn")
	assert_false(relic.SuppressesOwnCriticalHit(0, "Lance Thrust"),
		"Every other skill should be unaffected")

# --- Draught-Fed Edge ---

func _make_draught_fed_edge_setup(p_rarity: Types.Rarity) -> Dictionary:
	var character: Character = TestFactory.make_character()
	var relic: DraughtFedEdgeRelic = DraughtFedEdgeRelic.new()
	relic.Init(p_rarity)
	character._trait = relic
	character._skills = [_strike_skill("Strike"), TestFactory.make_empty_skill()]
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())
	return {"relic": relic, "resolver": resolver}

func test_draught_fed_edge_boosts_the_first_damaging_skill_after_a_reagent_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.25], [Types.Rarity.Legendary, 0.60]]:
		var setup: Dictionary = _make_draught_fed_edge_setup(rarity_and_expected[0])
		var relic: DraughtFedEdgeRelic = setup["relic"]
		var resolver: BattleResolver = setup["resolver"]
		relic.OnReagentConsumed(0, ReagentData.new(), resolver)

		var result: TraitSkillResult = relic.OnSkillCast(0, [3], "Strike", {}, resolver)

		assert_almost_eq(result._damage_multiplier, 1.0 + rarity_and_expected[1], 0.0001,
			"Rarity %s should boost the following damaging cast by its own ladder step" %
					Types.RarityName(rarity_and_expected[0]))

func test_draught_fed_edge_gives_no_bonus_without_a_reagent() -> void:
	var setup: Dictionary = _make_draught_fed_edge_setup(Types.Rarity.Legendary)
	var relic: DraughtFedEdgeRelic = setup["relic"]
	var resolver: BattleResolver = setup["resolver"]

	var result: TraitSkillResult = relic.OnSkillCast(0, [3], "Strike", {}, resolver)

	assert_almost_eq(result._damage_multiplier, 1.0, 0.0001)

func test_draught_fed_edge_bonus_stays_banked_through_a_non_damaging_cast() -> void:
	var setup: Dictionary = _make_draught_fed_edge_setup(Types.Rarity.Legendary)
	var relic: DraughtFedEdgeRelic = setup["relic"]
	var resolver: BattleResolver = setup["resolver"]
	relic.OnReagentConsumed(0, ReagentData.new(), resolver)

	var idle_result: TraitSkillResult = relic.OnSkillCast(0, [], "Idle", {}, resolver)
	assert_almost_eq(idle_result._damage_multiplier, 1.0, 0.0001,
		"A non-damaging cast should not consume the bonus")

	var strike_result: TraitSkillResult = relic.OnSkillCast(0, [3], "Strike", {}, resolver)
	assert_almost_eq(strike_result._damage_multiplier, 1.60, 0.0001,
		"The first damaging cast after the reagent should still get the bonus")

func test_draught_fed_edge_own_reagent_drawback_is_flat_not_laddered() -> void:
	for rarity in [Types.Rarity.Common, Types.Rarity.Legendary]:
		var setup: Dictionary = _make_draught_fed_edge_setup(rarity)
		var relic: DraughtFedEdgeRelic = setup["relic"]
		var resolver: BattleResolver = setup["resolver"]

		var potency: float = relic.OnReagentConsumed(0, ReagentData.new(), resolver)

		assert_almost_eq(potency, -0.40, 0.0001, "Rarity %s" % Types.RarityName(rarity))

# --- Threefold Bite ---

func _make_threefold_bite_setup(p_rarity: Types.Rarity) -> Dictionary:
	var character: Character = TestFactory.make_character()
	var relic: ThreefoldBiteRelic = ThreefoldBiteRelic.new()
	relic.Init(p_rarity)
	character._trait = relic
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())
	return {"relic": relic, "resolver": resolver}

var _echo_bonuses_call_count: int = 0

## Drives p_count real cascade instances through a plain Subscribe/Post/Drain, collecting the
## Relic's answer once per target in p_target_IDs per instance — the same "callback runs while
## CascadeResolver has an active depth" shape any real Echo-producing mechanic uses, and the
## same once-per-target polling BattleResolver._ResolveDamage does. Each call subscribes under
## a fresh mechanic key so an earlier call's still-registered listener (a test-harness
## artifact; a real mechanic subscribes once per battle) never shadows its dedup entry.
func _echo_bonuses(
		p_resolver: BattleResolver,
		p_relic: ThreefoldBiteRelic,
		p_count: int,
		p_target_IDs: Array[int] = [1]) -> Array[float]:
	var bonuses: Array[float] = []
	_echo_bonuses_call_count += 1
	var mechanic_key: StringName = StringName("TestMechanic%d" % _echo_bonuses_call_count)
	p_resolver.GetCascadeResolver().Subscribe(
			Types.Cascade_Trigger.Skill_Resolved,
			mechanic_key,
			func(_e: CascadeEvent) -> bool: return true,
			func(_e: CascadeEvent) -> void:
				for target_ID: int in p_target_IDs:
					bonuses.append(p_relic.GetOutgoingDamageBonus(0, target_ID, p_resolver)))
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = 0
	event.instance_count = p_count
	p_resolver.GetCascadeResolver().Post(event)
	p_resolver.GetCascadeResolver().Drain()
	return bonuses

func test_threefold_bite_bonuses_every_third_echo_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.60], [Types.Rarity.Legendary, 1.70]]:
		var setup: Dictionary = _make_threefold_bite_setup(rarity_and_expected[0])
		var bonuses: Array[float] = _echo_bonuses(setup["resolver"], setup["relic"], 4)

		assert_eq(bonuses, [0.0, 0.0, rarity_and_expected[1], 0.0],
			"Rarity %s should bonus only the third Echo" % Types.RarityName(rarity_and_expected[0]))

## The getter is polled once per target, so a Relic counting its own calls would bonus an
## area Echo's third target instead of the action's third Echo.
func test_threefold_bite_counts_echoes_not_targets_on_an_area_echo() -> void:
	var setup: Dictionary = _make_threefold_bite_setup(Types.Rarity.Legendary)

	var bonuses: Array[float] = _echo_bonuses(setup["resolver"], setup["relic"], 3, [1, 2, 3])

	assert_eq(bonuses, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.70, 1.70, 1.70],
		"Every target of the third Echo should bonus, and no target of the first two")

func test_threefold_bite_penalizes_damage_outside_a_cascade() -> void:
	var setup: Dictionary = _make_threefold_bite_setup(Types.Rarity.Legendary)
	var relic: ThreefoldBiteRelic = setup["relic"]
	var resolver: BattleResolver = setup["resolver"]

	var bonus: float = relic.GetOutgoingDamageBonus(0, 1, resolver)

	assert_almost_eq(bonus, -0.30, 0.0001, "Damage outside any cascade instance is not an Echo")

## End-to-end through a real Echo producer: a Sorcerer holding three Echo charges repeats its
## cast three times, and only the third repeat's damage carries the Relic's bonus bucket.
func test_threefold_bite_bonuses_the_third_echo_of_a_real_sorcerer_cast() -> void:
	var caster: Character = TestFactory.make_character()
	caster._current_health = 10
	caster._rarity = Types.Rarity.Rare
	var sorcerer_trait: SorcererTrait = SorcererTrait.new()
	sorcerer_trait.Init(Types.Rarity.Rare)
	caster._trait = sorcerer_trait
	caster._skills = [_strike_skill("Bolt")]
	var relic: ThreefoldBiteRelic = ThreefoldBiteRelic.new()
	relic.Init(Types.Rarity.Legendary)
	_equip_relic(caster, Types.Slot.Weapon, relic)
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 100000
	enemy._current_health = 400000
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	# Banked directly rather than through three reagents, which would also max Instability and
	# fire a Surge — an extra non-Echo damage instance unrelated to what this asserts.
	sorcerer_trait._echo_charges = 3

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var damage_results: Array[CombatResult] = _damage_results_against(results, 1)
	assert_eq(damage_results.size(), 4, "The base cast plus three Echoes")
	var bonus_key: StringName = &"trait_damage_bonus"
	var buckets: Array[float] = []
	for result: CombatResult in damage_results:
		buckets.append(result.combined_damage_modifier.Buckets().get(bonus_key, 0.0))
	assert_almost_eq(buckets[0], -0.30, 0.0001, "The base cast is not an Echo, so it takes the penalty")
	assert_almost_eq(buckets[1], 0.0, 0.0001, "First Echo: no bonus")
	assert_almost_eq(buckets[2], 0.0, 0.0001, "Second Echo: no bonus")
	assert_almost_eq(buckets[3], 1.70, 0.0001, "Third Echo carries the Legendary ladder step")

## Cut the Cloth's Tension repeats resolve through a trait-local loop that deliberately bypasses
## the CascadeResolver, so they only register as Echoes because that loop opens an Echo scope.
func test_threefold_bite_counts_a_trait_local_repeat_loop_as_echoes() -> void:
	var caster: Character = TestFactory.make_character()
	caster._current_health = 10
	caster._rarity = Types.Rarity.Rare
	var herald_trait: WeftAndWarpTrait = WeftAndWarpTrait.new()
	herald_trait.Init(Types.Rarity.Rare)
	caster._trait = herald_trait
	caster._skills = [_strike_skill("Cut the Cloth")]
	var relic: ThreefoldBiteRelic = ThreefoldBiteRelic.new()
	relic.Init(Types.Rarity.Legendary)
	_equip_relic(caster, Types.Slot.Weapon, relic)
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 100000
	enemy._current_health = 400000
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	herald_trait._tension = 3

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)

	var damage_results: Array[CombatResult] = _damage_results_against(results, 1)
	assert_eq(damage_results.size(), 4, "The base cast plus three Tension repeats")
	var buckets: Array[float] = []
	for result: CombatResult in damage_results:
		buckets.append(result.combined_damage_modifier.Buckets().get(&"trait_damage_bonus", 0.0))
	assert_almost_eq(buckets[0], -0.30, 0.0001, "The base cast is not an Echo")
	assert_almost_eq(buckets[1], 0.0, 0.0001, "First repeat: an Echo, no bonus")
	assert_almost_eq(buckets[2], 0.0, 0.0001, "Second repeat: an Echo, no bonus")
	assert_almost_eq(buckets[3], 1.70, 0.0001, "Third repeat carries the Legendary ladder step")

func test_threefold_bite_resets_the_echo_count_on_a_new_action() -> void:
	var setup: Dictionary = _make_threefold_bite_setup(Types.Rarity.Legendary)
	var relic: ThreefoldBiteRelic = setup["relic"]
	var resolver: BattleResolver = setup["resolver"]
	_echo_bonuses(resolver, relic, 3)

	resolver.GetCascadeResolver().ResetForNextAction()
	var bonuses: Array[float] = _echo_bonuses(resolver, relic, 3)

	assert_eq(bonuses, [0.0, 0.0, 1.70],
		"A new action's third Echo should bonus again rather than continuing the old count")

# --- Lantern of the Standing Ward ---

func _place_test_zone(p_resolver: BattleResolver, p_owner_ID: int, p_charges: int) -> void:
	var zone_effect: ZoneEffect = ZoneEffect.new()
	zone_effect.charges = p_charges
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	zone_effect.on_trigger = [damage]
	p_resolver.GetZoneResolver().PlaceZone(0, p_owner_ID, zone_effect, Types.Skill_Target.ZoneEnemy,
			p_resolver.GetEffectiveAttributes(p_owner_ID))

func _make_lantern_setup(p_rarity: Types.Rarity) -> Dictionary:
	var wearer: Character = TestFactory.make_character()
	wearer._current_health = 10
	var relic: LanternOfTheStandingWardRelic = LanternOfTheStandingWardRelic.new()
	relic.Init(p_rarity)
	wearer._trait = relic
	var target: Character = TestFactory.make_character()
	target._attributes[Types.Attribute.Health] = 1000
	target._current_health = 4000
	var characters: Dictionary[int, Character] = {0: wearer, 1: target}
	var fake_positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	fake_positions.characters_in_zones = true
	var resolver: BattleResolver = TestFactory.make_resolver(
			characters, CombatSides.new([0], [1]), fake_positions)
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	return {"relic": relic, "resolver": resolver, "fake_positions": fake_positions}

func test_lantern_echoes_the_first_charge_of_a_placed_zone_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.40], [Types.Rarity.Legendary, 0.75]]:
		var setup: Dictionary = _make_lantern_setup(rarity_and_expected[0])
		var resolver: BattleResolver = setup["resolver"]
		_place_test_zone(resolver, 0, 3)
		var received: Array[CombatResult] = []
		resolver.result_produced.connect(func(r: CombatResult) -> void: received.append(r))

		resolver.GetZoneResolver().TriggerZones(0)

		var damage_results: Array[CombatResult] = _damage_results_against(received, 1)
		assert_eq(damage_results.size(), 2,
			"Rarity %s should Echo the zone's first charge once" % Types.RarityName(rarity_and_expected[0]))
		assert_lt(damage_results[1].amount, damage_results[0].amount)

func test_lantern_only_echoes_the_first_charge() -> void:
	var setup: Dictionary = _make_lantern_setup(Types.Rarity.Legendary)
	var resolver: BattleResolver = setup["resolver"]
	var fake_positions: TestFactory.FakeTurnPositions = setup["fake_positions"]
	_place_test_zone(resolver, 0, 3)
	fake_positions.occupants_by_zone[0] = [1]
	resolver.GetZoneResolver().TriggerZones(0)  # first charge: Echoes

	# The target must leave and re-enter the zone to trigger it a second time
	# (once-per-visit re-triggering), independent of the Echo mechanic under test.
	fake_positions.occupants_by_zone[0] = []
	resolver.GetZoneResolver().TriggerZones(0)
	fake_positions.occupants_by_zone[0] = [1]
	var received: Array[CombatResult] = []
	resolver.result_produced.connect(func(r: CombatResult) -> void: received.append(r))
	resolver.GetZoneResolver().TriggerZones(0)  # second charge: should not Echo again

	assert_eq(_damage_results_against(received, 1).size(), 1,
		"Only the zone's first-ever charge should Echo")

func test_lantern_echoes_again_for_a_second_zone_in_a_recycled_section() -> void:
	var setup: Dictionary = _make_lantern_setup(Types.Rarity.Legendary)
	var resolver: BattleResolver = setup["resolver"]
	_place_test_zone(resolver, 0, 1)
	resolver.GetZoneResolver().TriggerZones(0)  # spends the only charge, clearing the zone
	assert_false(resolver.GetZoneResolver().HasZone(0), "The one-charge zone should have cleared")

	# A zone ID is a turn-bar section, freed for reuse once the zone in it clears.
	_place_test_zone(resolver, 0, 1)
	var received: Array[CombatResult] = []
	resolver.result_produced.connect(func(r: CombatResult) -> void: received.append(r))
	resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(_damage_results_against(received, 1).size(), 2,
		"A second zone placed in the same section should Echo on its own first charge")

func test_lantern_does_not_echo_a_zone_the_wearer_did_not_place() -> void:
	var setup: Dictionary = _make_lantern_setup(Types.Rarity.Legendary)
	var resolver: BattleResolver = setup["resolver"]
	_place_test_zone(resolver, 1, 3)  # placed by the enemy, not the wearer
	var received: Array[CombatResult] = []
	resolver.result_produced.connect(func(r: CombatResult) -> void: received.append(r))

	resolver.GetZoneResolver().TriggerZones(1)

	assert_eq(_damage_results_against(received, 0).size(), 1,
		"Only zones the wearer placed should Echo")

func test_lantern_scales_a_non_damage_zone_effect_too() -> void:
	var setup: Dictionary = _make_lantern_setup(Types.Rarity.Legendary)
	var resolver: BattleResolver = setup["resolver"]
	var zone_effect: ZoneEffect = ZoneEffect.new()
	zone_effect.charges = 3
	var bump: TurnBarEffect = TurnBarEffect.new()
	bump.fraction = 0.10
	zone_effect.on_trigger = [bump]
	resolver.GetZoneResolver().PlaceZone(0, 0, zone_effect, Types.Skill_Target.ZoneEnemy,
			resolver.GetEffectiveAttributes(0))
	var received: Array[CombatResult] = []
	resolver.result_produced.connect(func(r: CombatResult) -> void: received.append(r))

	resolver.GetZoneResolver().TriggerZones(0)

	var bumps: Array[CombatResult] = received.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Turn_Bar_Bump == r.kind and 1 == r.target_ID)
	assert_eq(bumps.size(), 2, "The Echo should resolve the zone's turn-bar effect a second time")
	assert_almost_eq(bumps[1].fraction, bumps[0].fraction * 0.75, 0.0001,
		"A non-damage zone effect must Echo at the Relic's own ladder step, not at full strength")

func test_lantern_team_reagent_drawback_is_flat_not_laddered() -> void:
	for rarity in [Types.Rarity.Common, Types.Rarity.Legendary]:
		var relic: LanternOfTheStandingWardRelic = LanternOfTheStandingWardRelic.new()
		relic.Init(rarity)

		assert_almost_eq(relic.GetTeamReagentPotencyBonus(0, null), -0.50, 0.0001,
			"Rarity %s" % Types.RarityName(rarity))

## A Lantern zone Echo now goes through CascadeResolver like any other Echo, so it must
## consume the shared fan-out budget and read as an Echo to another mechanic entirely.
func test_lantern_zone_echo_is_seen_as_an_echo_by_threefold_bite() -> void:
	var wearer: Character = TestFactory.make_character()
	wearer._current_health = 10
	var lantern: LanternOfTheStandingWardRelic = LanternOfTheStandingWardRelic.new()
	lantern.Init(Types.Rarity.Legendary)
	wearer._trait = lantern
	var threefold_bite: ThreefoldBiteRelic = ThreefoldBiteRelic.new()
	threefold_bite.Init(Types.Rarity.Legendary)
	_equip_relic(wearer, Types.Slot.Weapon, threefold_bite)
	var target: Character = TestFactory.make_character()
	target._attributes[Types.Attribute.Health] = 100000
	target._current_health = 400000
	var characters: Dictionary[int, Character] = {0: wearer, 1: target}
	var fake_positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	fake_positions.characters_in_zones = true
	var resolver: BattleResolver = TestFactory.make_resolver(
			characters, CombatSides.new([0], [1]), fake_positions)
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	_place_test_zone(resolver, 0, 1)
	var received: Array[CombatResult] = []
	resolver.result_produced.connect(func(r: CombatResult) -> void: received.append(r))

	resolver.GetZoneResolver().TriggerZones(0)

	var damage_results: Array[CombatResult] = _damage_results_against(received, 1)
	assert_eq(damage_results.size(), 2, "The base zone hit plus the Lantern's Echo")
	var bonus_key: StringName = &"trait_damage_bonus"
	assert_almost_eq(damage_results[0].combined_damage_modifier.Buckets().get(bonus_key, 0.0), -0.30, 0.0001,
		"The base zone trigger is not an Echo, so Threefold Bite's non-Echo penalty applies")
	assert_eq(damage_results[1].combined_damage_modifier.Buckets().get(bonus_key, 0.0), 0.0,
		"The Lantern's zone Echo must not take Threefold Bite's non-Echo penalty")
	assert_eq(damage_results[1].cascade_depth, 1, "The zone Echo should carry a real cascade depth")
