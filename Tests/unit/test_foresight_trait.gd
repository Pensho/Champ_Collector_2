extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _enemy: Character = null
var _trait: ForesightTrait = null
var _characters: Dictionary[int, Character]
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_owner = Character.new()
	_enemy = Character.new()
	_owner._current_health = 10
	_enemy._current_health = 10
	_trait = ForesightTrait.new()
	_characters = {0: _owner, 1: _enemy}
	_positions = TestFactory.FakeTurnPositions.new()
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]), _positions)

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_owner._rarity = p_rarity
	_trait.Init(p_rarity)

# --- Rarity tables ---

func test_percent_behind_threshold_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.10,
		Types.Rarity.Rare: 0.15,
		Types.Rarity.Epic: 0.20,
		Types.Rarity.Legendary: 0.25,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(ForesightTrait.PERCENT_BEHIND_THRESHOLD.get(rarity, 0.0), expected[rarity],
			"PERCENT_BEHIND_THRESHOLD at %s" % Types.RarityName(rarity))

# --- Enemies within threshold are debuffed at every rarity ---

func test_enemy_within_threshold_is_enfeebled_at_low_rarity() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_enemy._active_debuffs.size(), 1, "Enemy within threshold should be enfeebled at any rarity")
	assert_eq(_enemy._active_debuffs[0].type, Types.Debuff_Type.Enfeeble)
	assert_eq(_enemy._active_debuffs[0].duration, 1)

func test_enemy_within_threshold_is_enfeebled_at_high_rarity() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_enemy._active_debuffs.size(), 1, "Enemy within threshold should be enfeebled at Legendary rarity")

func test_no_debuff_when_no_enemies_within_threshold() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_positions.behind_IDs = []

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_enemy._active_debuffs.size(), 0,
		"No debuff should be applied when no enemies qualify as within threshold")

# --- Allies excluded ---

func test_ally_behind_is_not_enfeebled() -> void:
	var ally: Character = Character.new()
	ally._current_health = 10
	_characters[2] = ally
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 2], [1]), _positions)
	_InitTrait(Types.Rarity.Legendary)
	_positions.behind_IDs = [1, 2]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(ally._active_debuffs.size(), 0, "Allies behind on the turn bar should never be enfeebled")
	assert_eq(_enemy._active_debuffs.size(), 1, "Enemies behind on the turn bar should still be enfeebled")

# --- Debuff source ---

func test_debuff_source_is_the_diviner() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_enemy._active_debuffs[0].source_ID, 0)

func test_threshold_queried_matches_rarity() -> void:
	_InitTrait(Types.Rarity.Epic)
	_positions.behind_IDs = []

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_positions.last_behind_query, [0, 0.20],
		"Epic rarity should query the turn positions with a 20% threshold")
