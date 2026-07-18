extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally: Character = null
var _trait: PlanTrait = null
var _characters: Dictionary[int, Character]
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_owner = Character.new()
	_ally = Character.new()
	# Living combatants — the Plan trait's targeting excludes dead allies.
	_owner._current_health = 10
	_ally._current_health = 10
	_trait = PlanTrait.new()
	_characters = {0: _owner, 1: _ally}
	_positions = TestFactory.FakeTurnPositions.new()
	# A two-player side with no enemies — exercises a sub-3 team on purpose.
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1], []), _positions)

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
		assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(rarity, 0.0), expected[rarity],
			"PERCENT_BEHIND_THRESHOLD at %s" % Types.RarityName(rarity))

# --- The Tactician itself is never buffed ---

func test_owner_is_never_empowered() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_owner._active_buffs.size(), 0, "Tactician should not buff itself")

# --- Allies within threshold are buffed at every rarity ---

func test_ally_within_threshold_is_empowered_at_low_rarity() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_ally._active_buffs.size(), 1, "Ally within threshold should be empowered at any rarity")
	assert_eq(_ally._active_buffs[0].type, Types.Buff_Type.Empower)

func test_ally_within_threshold_is_empowered_at_high_rarity() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_ally._active_buffs.size(), 1, "Ally within threshold should be empowered at Legendary rarity")

func test_no_buff_when_no_allies_within_threshold() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_positions.behind_IDs = []

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_ally._active_buffs.size(), 0,
		"No ally buff should be applied when none qualify as within threshold")

func test_threshold_queried_matches_rarity() -> void:
	_InitTrait(Types.Rarity.Epic)
	_positions.behind_IDs = []

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_positions.last_behind_query, [0, 0.20],
		"Epic rarity should query the turn positions with a 20% threshold")
