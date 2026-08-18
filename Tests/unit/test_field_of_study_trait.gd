extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally: Character = null
var _enemy: Character = null
var _trait: FieldOfStudyTrait = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_owner = TestFactory.make_character()
	_ally = TestFactory.make_character()
	_enemy = TestFactory.make_character()
	for character in [_owner, _ally, _enemy]:
		character._current_health = character._attributes[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var characters: Dictionary[int, Character] = {0: _owner, 1: _ally, 2: _enemy}
	_resolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], [2]))
	_trait = FieldOfStudyTrait.new()
	_owner._trait = _trait

# --- Rarity ladder ---

func test_amplification_by_rarity() -> void:
	assert_almost_eq(FieldOfStudyTrait.GetAmplification(Types.Rarity.Uncommon), 0.07, 0.0001)
	assert_almost_eq(FieldOfStudyTrait.GetAmplification(Types.Rarity.Rare), 0.08, 0.0001)
	assert_almost_eq(FieldOfStudyTrait.GetAmplification(Types.Rarity.Epic), 0.09, 0.0001)
	assert_almost_eq(FieldOfStudyTrait.GetAmplification(Types.Rarity.Legendary), 0.11, 0.0001)

func test_get_applied_attribute_amplification_reads_the_rarity_ladder() -> void:
	_trait.Init(Types.Rarity.Legendary)
	assert_almost_eq(_trait.GetAppliedAttributeAmplification(), 0.11, 0.0001)

# --- Sharp Rebuttal's zone gate ---

func test_get_condition_count_is_zero_with_no_zones_standing() -> void:
	_trait.Init(Types.Rarity.Legendary)
	assert_eq(_trait.GetConditionCount(0, 2, Types.Trait_Count_Source.Trait_Condition, _resolver), 0.0)

func test_get_condition_count_reads_the_live_zone_count() -> void:
	_trait.Init(Types.Rarity.Legendary)
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(3), Types.Skill_Target.Skill_Default)

	assert_eq(_trait.GetConditionCount(0, 2, Types.Trait_Count_Source.Trait_Condition, _resolver), 1.0)

func test_get_condition_count_ignores_other_count_sources() -> void:
	_trait.Init(Types.Rarity.Legendary)
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(3), Types.Skill_Target.Skill_Default)

	assert_eq(_trait.GetConditionCount(0, 2, Types.Trait_Count_Source.Buffs_On_Caster, _resolver), 0.0)
