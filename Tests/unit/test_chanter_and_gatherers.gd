extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Chanter and Gatherers (Encounter_Design_Document.md 2.2): a Gatherer's triangle
# starts at one part, gains one a turn, hovers when full and launches at the party the turn after;
# an Enfeeble landing on a Gatherer is consumed and empties its triangle; the Chanter's Chant
# Enfeebles every character on both sides.

const GATHERER_TRAIT: GathererTrait = preload("res://Data/Character_Traits/Enemy_Traits/Gatherer_Trait.tres")
const CHANT: Skill = preload("res://Data/Character_Skill_Variants/Support_Skills/Chant.tres")
const GATHERER_ID: int = 3
const CHANTER_ID: int = 4
const PARTY_IDS: Array[int] = [0, 1, 2]
const ALL_IDS: Array[int] = [0, 1, 2, 3, 4, 5]

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _trait: GathererTrait = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_trait = GATHERER_TRAIT.duplicate(true)
	_trait.Init(Types.Rarity.Common)
	_roster[GATHERER_ID]._trait = _trait
	_trait.StartOfBattle(GATHERER_ID, _resolver)

func _start_turns(p_count: int) -> void:
	for turn in p_count:
		_resolver.BeginTurn(GATHERER_ID)

func _enfeeble() -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.duration = 1
	debuff.source_ID = CHANTER_ID
	return debuff

func _holds_enfeeble(p_ID: int) -> bool:
	return _roster[p_ID]._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Enfeeble == debuff.type)

func _party_health() -> Array[int]:
	var health: Array[int] = []
	for party_ID in PARTY_IDS:
		health.append(_roster[party_ID]._current_health)
	return health

func test_a_triangle_starts_with_one_part() -> void:
	assert_eq(_trait.GetParts(), 1)

func test_a_full_triangle_hovers_a_turn_then_launches_at_the_party() -> void:
	_start_turns(2)
	assert_eq(_trait.GetParts(), 3)
	var before: Array[int] = _party_health()
	_start_turns(1)
	assert_eq(_trait.GetParts(), 0, "The launch empties the triangle")
	for index in PARTY_IDS.size():
		assert_lt(_roster[PARTY_IDS[index]]._current_health, before[index], "The launch hits every champion")

func test_an_enfeeble_empties_the_triangle() -> void:
	_start_turns(1)
	_resolver.GetStatusResolver().ApplyDebuff(GATHERER_ID, _enfeeble())
	assert_eq(_trait.GetParts(), 0)
	assert_false(_holds_enfeeble(GATHERER_ID), "The Enfeeble should be consumed")

func test_a_consumed_enfeeble_is_announced_once() -> void:
	var results: Array[CombatResult] = _resolver.GetStatusResolver().ApplyDebuff(GATHERER_ID, _enfeeble())
	var announcements: Array[CombatResult] = results.filter(func(result: CombatResult) -> bool:
		return (CombatResult.Kind.Trait_Text == result.kind
				or (CombatResult.Kind.Status_Applied == result.kind and not result.is_buff)))
	assert_eq(announcements.size(), 1)

func test_the_chant_enfeebles_every_character_and_empties_the_triangles() -> void:
	_roster[CHANTER_ID]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[CHANTER_ID]._skills = [CHANT]
	_start_turns(1)
	_resolver.ResolveSkill(CHANTER_ID, ALL_IDS, 0)
	for character_ID in [0, 1, 2, CHANTER_ID, 5]:
		assert_true(_holds_enfeeble(character_ID), "Character %d should be Enfeebled" % character_ID)
	assert_false(_holds_enfeeble(GATHERER_ID), "The Gatherer consumes its Enfeeble")
	assert_eq(_trait.GetParts(), 0)
