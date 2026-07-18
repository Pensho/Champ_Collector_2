extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _trait: HemoclarityTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func before_each() -> void:
	_character = Character.new()
	_trait = HemoclarityTrait.new()
	_characters = {0: _character}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], []))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

# --- MYSTICISM_BONUS table ---

func test_mysticism_bonus_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.25,
		Types.Rarity.Rare: 0.30,
		Types.Rarity.Epic: 0.35,
		Types.Rarity.Legendary: 0.40,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(HemoclarityTrait.MYSTICISM_BONUS.get(rarity, 0.0), expected[rarity],
			"MYSTICISM_BONUS at %s" % Types.RarityName(rarity))

# --- Health threshold behaviour ---

func test_below_half_health_increases_mysticism() -> void:
	_InitTrait(Types.Rarity.Epic)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 199 # below 50% of 100 * ATTRIBUTE_HEALTH_MULTIPLIER (4) = 400

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	# Epic = 35% bonus, ceil(100 * 0.35) = 35
	assert_eq(attributes[Types.Attribute.Mysticism], 135,
		"Mysticism should be boosted by 35% while below half health")

func test_at_half_health_no_bonus() -> void:
	_InitTrait(Types.Rarity.Epic)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 200 # exactly 50% of max health (400)

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"No bonus should apply at exactly half health")

func test_above_half_health_no_bonus() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 400 # full health

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"No bonus should apply above half health")

func test_rarity_scaling_uncommon_vs_epic() -> void:
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 1 # near zero, below half

	var uncommon_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_InitTrait(Types.Rarity.Uncommon)
	_trait.OnSkillCast(0, [], "Fireball", uncommon_attr, _resolver)
	assert_eq(uncommon_attr[Types.Attribute.Mysticism], 125,
		"Uncommon should give +25% Mysticism")

	var epic_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Fireball", epic_attr, _resolver)
	assert_eq(epic_attr[Types.Attribute.Mysticism], 135,
		"Epic should give +35% Mysticism")

# --- Max health guard ---

func test_zero_max_health_does_not_divide_by_zero() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_character._attributes[Types.Attribute.Health] = 0
	_character._current_health = 0

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"Zero max health should be guarded and apply no bonus")
