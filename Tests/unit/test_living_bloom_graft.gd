extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const LIVING_BLOOM_PATH: String = "res://Data/Character_Traits/Grafts/Living_Bloom_Graft.tres"

func _make_living_bloom(p_rarity: Types.Rarity) -> LivingBloomGraft:
	var graft: LivingBloomGraft = load(LIVING_BLOOM_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func test_start_of_battle_seeds_a_max_charge_spore_zone_in_a_free_slot() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0].ApplyGraft(load(LIVING_BLOOM_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	(roster[0]._trait as LivingBloomGraft).StartOfBattle(0, resolver)

	var zones: Dictionary[int, Zone] = resolver.GetZoneResolver().GetZones()
	assert_eq(zones.size(), 1)
	var zone: Zone = zones.values()[0]
	assert_eq(zone._on_trigger.size(), 2, "Spore Bloom should regenerate allies and blight enemies on trigger")
	assert_eq(zone._charges, LivingBloomGraft.MAX_CHARGES)
	assert_eq(zone._owner_ID, 0)
	assert_eq((roster[0]._trait as LivingBloomGraft)._bloom_zone_ID, zones.keys()[0])

func test_start_of_battle_no_ops_when_no_slots_are_free() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0].ApplyGraft(load(LIVING_BLOOM_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	for zone_number in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
		var filler_effect: ZoneEffect = TestFactory.make_zone_effect(3)
		TestFactory.place_zone(resolver, zone_number, 0, filler_effect, Types.Skill_Target.ZoneAll)

	(roster[0]._trait as LivingBloomGraft).StartOfBattle(0, resolver)

	assert_eq((roster[0]._trait as LivingBloomGraft)._bloom_zone_ID, -1)
	for zone in resolver.GetZoneResolver().GetZones().values():
		zone.free()

func test_start_of_turn_tops_the_bloom_up_by_one_charge() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0].ApplyGraft(load(LIVING_BLOOM_PATH))
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.characters_in_zones = true
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	# Only the owner (0) and one other participant (1) are alive, so a single
	# TriggerZones call spends exactly one charge.
	for id in [2, 3, 4, 5]:
		roster[id]._current_health = 0
	var graft: LivingBloomGraft = roster[0]._trait as LivingBloomGraft
	graft.StartOfBattle(0, resolver)
	resolver.GetZoneResolver().TriggerZones(0)  # Spend one charge.
	assert_eq(resolver.GetZoneResolver().GetZones()[graft._bloom_zone_ID]._charges, LivingBloomGraft.MAX_CHARGES - 1)

	graft.StartOfTurn(0, resolver)

	assert_eq(resolver.GetZoneResolver().GetZones()[graft._bloom_zone_ID]._charges, LivingBloomGraft.MAX_CHARGES)
	for zone in resolver.GetZoneResolver().GetZones().values():
		zone.free()

func test_start_of_turn_never_replenishes_past_the_max() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0].ApplyGraft(load(LIVING_BLOOM_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: LivingBloomGraft = roster[0]._trait as LivingBloomGraft
	graft.StartOfBattle(0, resolver)

	graft.StartOfTurn(0, resolver)

	assert_eq(resolver.GetZoneResolver().GetZones()[graft._bloom_zone_ID]._charges, LivingBloomGraft.MAX_CHARGES)
	for zone in resolver.GetZoneResolver().GetZones().values():
		zone.free()

func test_start_of_turn_is_safe_once_the_bloom_has_dissipated() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0].ApplyGraft(load(LIVING_BLOOM_PATH))
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)
	var graft: LivingBloomGraft = roster[0]._trait as LivingBloomGraft
	graft.StartOfBattle(0, resolver)
	var zone_ID: int = graft._bloom_zone_ID
	# Once-per-visit means a still-standing character is only affected once; cycle one
	# character out and back in each round so every call spends a fresh charge.
	positions.occupants_by_zone[zone_ID] = [2]
	for _i in range(LivingBloomGraft.MAX_CHARGES):
		resolver.GetZoneResolver().TriggerZones(1)
		positions.occupants_by_zone[zone_ID] = []
		resolver.GetZoneResolver().TriggerZones(1)
		positions.occupants_by_zone[zone_ID] = [2]
	assert_false(resolver.GetZoneResolver().HasZone(zone_ID))

	graft.StartOfTurn(0, resolver)  # Must not error and must not re-seed the Bloom.

	assert_false(resolver.GetZoneResolver().HasZone(zone_ID))
