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

# --- Continuous missing-Health curve ---

func test_missing_health_increases_mysticism_continuously() -> void:
	_InitTrait(Types.Rarity.Epic)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 200 # 50% missing of max health (400)

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	# Epic = 0.9%/1% missing, 50% missing -> +45%, ceil(100 * 0.45) = 45
	assert_eq(attributes[Types.Attribute.Mysticism], 145,
		"Mysticism should scale continuously with missing Health")

func test_full_health_no_bonus() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 400 # full health

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"No bonus should apply at full health")

func test_bonus_caps_at_80_percent_missing() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 80 # exactly 80% missing of max health (400)

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	# Legendary = 1.0%/1% missing, capped at 80% -> +80%, ceil(100 * 0.8) = 80
	assert_eq(attributes[Types.Attribute.Mysticism], 180,
		"Bonus should reach its cap at exactly 80% missing Health")

func test_bonus_stays_capped_beyond_80_percent_missing() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 0 # 100% missing

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	assert_eq(attributes[Types.Attribute.Mysticism], 180,
		"Bonus should not grow past the 80% missing Health cap")

# --- Max health guard ---

func test_zero_max_health_does_not_divide_by_zero() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_character._attributes[Types.Attribute.Health] = 0
	_character._current_health = 0

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Fireball", attributes, _resolver)

	assert_eq(attributes[Types.Attribute.Mysticism], 100,
		"Zero max health should be guarded and apply no bonus")

# --- Outgoing restoration multiplier ---

func test_restoration_multiplier_matches_missing_health_bonus() -> void:
	_InitTrait(Types.Rarity.Epic)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 200 # 50% missing

	var multiplier: float = _trait.GetOutgoingRestorationMultiplier(0, _resolver)

	assert_almost_eq(multiplier, 1.45, 0.001,
		"Restoration multiplier should rise with the Bloodmage's own missing Health")

func test_restoration_multiplier_is_neutral_at_full_health() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_character._attributes[Types.Attribute.Health] = 100
	_character._current_health = 400 # full health

	var multiplier: float = _trait.GetOutgoingRestorationMultiplier(0, _resolver)

	assert_eq(multiplier, 1.0, "Restoration multiplier should be neutral at full health")
