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
	_trait.Init()
	_characters = {0: _owner, 1: _ally}
	_positions = TestFactory.FakeTurnPositions.new()
	# A two-player side with no enemies — exercises a sub-3 team on purpose.
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1], []), _positions)

# --- Rarity tables ---

func test_percent_behind_threshold_uncommon() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Uncommon, 0.0), 0.10)

func test_percent_behind_threshold_rare() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Rare, 0.0), 0.15)

func test_percent_behind_threshold_epic() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Epic, 0.0), 0.20)

func test_percent_behind_threshold_legendary() -> void:
	assert_eq(PlanTrait.PERCENT_BEHIND_THRESHOLD.get(Types.Rarity.Legendary, 0.0), 0.25)

# --- The Tactician itself is never buffed ---

func test_owner_is_never_empowered() -> void:
	_owner._rarity = Types.Rarity.Legendary
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_owner._active_buffs.size(), 0, "Tactician should not buff itself")

# --- Allies within threshold are buffed at every rarity ---

func test_ally_within_threshold_is_empowered_at_low_rarity() -> void:
	_owner._rarity = Types.Rarity.Uncommon
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_ally._active_buffs.size(), 1, "Ally within threshold should be empowered at any rarity")
	assert_eq(_ally._active_buffs[0].type, Types.Buff_Type.Empower)

func test_ally_within_threshold_is_empowered_at_high_rarity() -> void:
	_owner._rarity = Types.Rarity.Legendary
	_positions.behind_IDs = [1]

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_ally._active_buffs.size(), 1, "Ally within threshold should be empowered at Legendary rarity")

func test_no_buff_when_no_allies_within_threshold() -> void:
	_owner._rarity = Types.Rarity.Legendary
	_positions.behind_IDs = []

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_ally._active_buffs.size(), 0,
		"No ally buff should be applied when none qualify as within threshold")

func test_threshold_queried_matches_rarity() -> void:
	_owner._rarity = Types.Rarity.Epic
	_positions.behind_IDs = []

	_trait.StartOfTurn(0, _resolver)

	assert_eq(_positions.last_behind_query, [0, 0.20],
		"Epic rarity should query the turn positions with a 20% threshold")
