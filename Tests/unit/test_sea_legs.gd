extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Sea Legs (The Gilded Deck's own on_trigger payload): the boarding
# character's own highest base primary attribute, scaled by the deck owner's
# Knowledge, accumulating in place up to a 4-stack cap, and surviving self-ticks
# since it never expires.

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_positions.characters_in_zones = true
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	for id in [2, 3, 4, 5]:
		_roster[id]._current_health = 0

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _place_deck(p_per_stack_rate: float = 0.08) -> void:
	var sea_legs: SeaLegsZoneEffect = SeaLegsZoneEffect.new()
	sea_legs.per_stack_rate = p_per_stack_rate
	var zone_effect: ZoneEffect = TestFactory.make_zone_effect(10, [sea_legs])
	TestFactory.place_zone(_resolver, 0, 0, zone_effect, Types.Skill_Target.ZoneAlly)

func _sea_legs_buff() -> StatusEffects.Buff:
	for buff in _roster[1]._active_buffs:
		if(Types.Buff_Type.Sea_Legs == buff.type):
			return buff
	return null

func test_boarding_grants_sea_legs_on_the_holders_own_highest_attribute() -> void:
	_place_deck()
	_resolver.GetZoneResolver().TriggerZones(0)
	var buff: StatusEffects.Buff = _sea_legs_buff()
	assert_not_null(buff)
	# make_character's default spread has Attack (8) as the highest primary attribute.
	assert_eq(buff.trait_riders[&"attribute"], Types.Attribute.Attack)
	assert_eq(buff.trait_riders[&"stacks"], 1)

func test_attribute_choice_breaks_ties_toward_the_earlier_listed_attribute() -> void:
	_roster[1]._attributes[Types.Attribute.Defence] = 8  # ties Attack's default 8
	_place_deck()
	_resolver.GetZoneResolver().TriggerZones(0)
	assert_eq(_sea_legs_buff().trait_riders[&"attribute"], Types.Attribute.Attack,
		"Attack precedes Defence in the tie-break order")

func test_value_scales_with_the_decks_owner_knowledge() -> void:
	_roster[0]._attributes[Types.Attribute.Knowledge] = 200  # zone_magnitude = 1 + 200 * 0.005 = 2.0
	_place_deck(0.08)
	_resolver.GetZoneResolver().TriggerZones(0)
	assert_almost_eq(_sea_legs_buff().value, 0.08 * 2.0, 0.0001)

## Once-per-visit means a still-standing ally is only affected once; cycle them out
## and back in each call so every call produces a fresh trigger.
func _board_again() -> void:
	_positions.occupants_by_zone[0] = []
	_resolver.GetZoneResolver().TriggerZones(0)
	_positions.occupants_by_zone[0] = [1]
	_resolver.GetZoneResolver().TriggerZones(0)

func test_stacks_accumulate_and_value_scales_with_stack_count() -> void:
	_roster[0]._attributes[Types.Attribute.Knowledge] = 0  # zone_magnitude = 1.0
	_place_deck(0.08)
	_resolver.GetZoneResolver().TriggerZones(0)
	_board_again()

	assert_eq(_sea_legs_buff().trait_riders[&"stacks"], 2)
	assert_almost_eq(_sea_legs_buff().value, 0.08 * 2, 0.0001)

func test_stacks_cap_at_four() -> void:
	_roster[0]._attributes[Types.Attribute.Knowledge] = 0  # zone_magnitude = 1.0
	_place_deck(0.08)
	_resolver.GetZoneResolver().TriggerZones(0)
	for i in 5:
		_board_again()
	assert_eq(_sea_legs_buff().trait_riders[&"stacks"], 4, "Sea Legs must not exceed 4 stacks")
	assert_almost_eq(_sea_legs_buff().value, 0.08 * 4, 0.0001)

func test_only_one_sea_legs_instance_is_ever_held() -> void:
	_place_deck()
	_resolver.GetZoneResolver().TriggerZones(0)
	for i in 3:
		_board_again()
	var sea_legs_count: int = _roster[1]._active_buffs.filter(
			func(b): return Types.Buff_Type.Sea_Legs == b.type).size()
	assert_eq(sea_legs_count, 1, "Stacking must accumulate in place, not add a second instance")

func test_sea_legs_survives_the_holders_own_self_tick() -> void:
	_place_deck()
	_resolver.GetZoneResolver().TriggerZones(0)
	assert_not_null(_sea_legs_buff())

	_roster[1]._skills.append(TestFactory.make_empty_skill())
	_resolver.ResolveSkill(1, [], 0)
	_resolver.ResolveSkill(1, [], 0)
	_resolver.ResolveSkill(1, [], 0)

	assert_not_null(_sea_legs_buff(), "A permanent buff must not expire across the holder's own turns")

func test_the_grant_reaches_active_attribute_modifiers() -> void:
	_place_deck(0.10)
	_resolver.GetZoneResolver().TriggerZones(0)
	var attributes: Dictionary[Types.Attribute, int] = _roster[1].GetBaseAttributes()
	Skills.ApplyActiveAttributeModifiers(_roster[1], attributes)
	assert_eq(attributes[Types.Attribute.Attack], 8 + int(ceilf(8 * 0.10)))

## A second boarding must report Status_Applied under the SAME status_ID as the first (so the
## UI updates the existing icon's tooltip in place rather than allocating a second one for what
## is, in combat state, still one buff instance) and carry the new stacked value.
func test_restacking_reports_the_same_status_id_with_the_updated_value() -> void:
	_roster[0]._attributes[Types.Attribute.Knowledge] = 0  # zone_magnitude = 1.0
	_place_deck(0.08)
	var is_sea_legs_applied: Callable = func(r: CombatResult) -> bool:
		return (CombatResult.Kind.Status_Applied == r.kind and r.is_buff
				and Types.Buff_Type.Sea_Legs == r.buff_type)

	var first_results: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)
	var first_applied: CombatResult = first_results.filter(is_sea_legs_applied)[0]

	_positions.occupants_by_zone[0] = []
	_resolver.GetZoneResolver().TriggerZones(0)
	_positions.occupants_by_zone[0] = [1]
	var second_results: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)
	var second_applied: CombatResult = second_results.filter(is_sea_legs_applied)[0]

	assert_eq(second_applied.status_ID, first_applied.status_ID,
		"Restacking must report the same status_ID, not a new one, so the UI updates in place")
	assert_almost_eq(second_applied.fraction, 0.08 * 2, 0.0001,
		"The reported value must reflect the new stack count for the {percent} tooltip token")
