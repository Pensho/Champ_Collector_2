extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Regression coverage for the Bloodmage's shipped kit (Role_Kit_Design.md 9.4): Transfusion's
# team-wide Barrier/Sanguine Pact grant, scaled by Hemoclarity's restoration multiplier.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[0]._skills.append(load("res://Data/Character_Skill_Variants/Support_Skills/Transfusion.tres"))

func _barrier_value(p_character: Character) -> float:
	for buff in p_character._active_buffs:
		if(Types.Buff_Type.Barrier == buff.type):
			return buff.value
	return -1.0

func _has_sanguine_pact(p_character: Character) -> bool:
	for buff in p_character._active_buffs:
		if(Types.Buff_Type.Sanguine_Pact == buff.type):
			return true
	return false

func test_transfusion_grants_barrier_and_sanguine_pact_to_every_other_ally() -> void:
	_resolver.ResolveSkill(0, [1, 2], 0)

	assert_gt(_barrier_value(_roster[1]), 0.0, "Transfusion's Barrier should reach every other ally")
	assert_gt(_barrier_value(_roster[2]), 0.0, "Transfusion's Barrier should reach every other ally")
	assert_true(_has_sanguine_pact(_roster[1]), "Transfusion should grant Sanguine Pact to every other ally")
	assert_true(_has_sanguine_pact(_roster[2]), "Transfusion should grant Sanguine Pact to every other ally")

func test_sanguine_pact_records_transfusions_caster_as_its_applier() -> void:
	_resolver.ResolveSkill(0, [1, 2], 0)

	for buff in _roster[1]._active_buffs:
		if(Types.Buff_Type.Sanguine_Pact == buff.type):
			assert_eq(buff.source_ID, 0, "Sanguine Pact should record the Bloodmage as its applier")
			return
	fail_test("Sanguine Pact was not granted")

func test_transfusions_barrier_is_scaled_by_hemoclaritys_restoration_multiplier() -> void:
	var max_health: int = _resolver.GetMaxHealth(0)
	_roster[0]._current_health = int(round(max_health * 0.5)) # 50% missing

	var unscaled_resolver: BattleResolver = TestFactory.make_resolver(
			TestFactory.make_full_roster(), TestFactory.make_full_sides())
	unscaled_resolver.GetCharacters()[0]._skills.append(
			load("res://Data/Character_Skill_Variants/Support_Skills/Transfusion.tres"))
	unscaled_resolver.ResolveSkill(0, [1, 2], 0)
	var unscaled_barrier: float = _barrier_value(unscaled_resolver.GetCharacters()[1])

	var hemoclarity: HemoclarityTrait = HemoclarityTrait.new()
	hemoclarity.Init(Types.Rarity.Legendary)
	_roster[0]._trait = hemoclarity
	_resolver.ResolveSkill(0, [1, 2], 0)
	var scaled_barrier: float = _barrier_value(_roster[1])

	assert_gt(scaled_barrier, unscaled_barrier,
		"Hemoclarity should scale up the Barrier Transfusion grants while the Bloodmage is wounded")
