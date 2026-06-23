extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")
const BATTLE_UI_SCRIPT = preload("res://Scripts/UI/Battle_UI/battle_ui.gd")

var _repr: CharacterRepresentation = null
var _battle_ui: BattleUI = null
var _trait: DoubleTheFunTrait = null

func before_each() -> void:
	_repr = double(REPR_SCRIPT).new()
	_battle_ui = double(BATTLE_UI_SCRIPT).new()
	_trait = DoubleTheFunTrait.new()
	_trait.Init()

func after_each() -> void:
	_repr.free()
	_battle_ui.free()

# --- AVOIDANCE_INCREMENT table ---

func test_avoidance_increment_uncommon() -> void:
	assert_eq(DoubleTheFunTrait.AVOIDANCE_INCREMENT.get(Types.Rarity.Uncommon, 0.0), 0.03)

func test_avoidance_increment_rare() -> void:
	assert_eq(DoubleTheFunTrait.AVOIDANCE_INCREMENT.get(Types.Rarity.Rare, 0.0), 0.04)

func test_avoidance_increment_epic() -> void:
	assert_eq(DoubleTheFunTrait.AVOIDANCE_INCREMENT.get(Types.Rarity.Epic, 0.0), 0.05)

func test_avoidance_increment_legendary() -> void:
	assert_eq(DoubleTheFunTrait.AVOIDANCE_INCREMENT.get(Types.Rarity.Legendary, 0.0), 0.06)

# --- Chance computation boundaries ---

func test_base_chance_at_zero_stacks() -> void:
	assert_eq(_trait.GetAvoidChance(Types.Rarity.Legendary), 0.05)

func test_chance_ramps_per_stack_epic() -> void:
	_trait._avoidance_stacks = 1
	assert_almost_eq(_trait.GetAvoidChance(Types.Rarity.Epic), 0.10, 0.0001)
	_trait._avoidance_stacks = 2
	assert_almost_eq(_trait.GetAvoidChance(Types.Rarity.Epic), 0.15, 0.0001)
	_trait._avoidance_stacks = 3
	assert_almost_eq(_trait.GetAvoidChance(Types.Rarity.Epic), 0.20, 0.0001)

func test_max_chance_legendary() -> void:
	_trait._avoidance_stacks = DoubleTheFunTrait.MAX_AVOIDANCE_STACKS
	assert_almost_eq(_trait.GetAvoidChance(Types.Rarity.Legendary), 0.23, 0.0001)

# --- Stack ramp / cap / reset behaviour (driven via OnDamageTaken outcomes) ---

func test_stacks_increment_on_a_hit() -> void:
	_trait._avoidance_stacks = 0
	var multiplier: float = _trait.OnDamageTaken(_repr, Types.Rarity.Uncommon, _battle_ui)
	if multiplier == 1.0:
		assert_eq(_trait._avoidance_stacks, 1, "A hit (no avoid) should increment stacks by 1")
	else:
		assert_eq(_trait._avoidance_stacks, 0, "An avoid should reset stacks to 0")

func test_stacks_cap_at_max_after_repeated_hits() -> void:
	# Common rarity has no entry in AVOIDANCE_INCREMENT, so chance stays at the 5% base
	# regardless of stacks. Driving many calls makes repeated hits overwhelmingly likely
	# while keeping the cap assertion deterministic.
	for i in 200:
		_trait.OnDamageTaken(_repr, Types.Rarity.Common, _battle_ui)
	assert_true(_trait._avoidance_stacks <= DoubleTheFunTrait.MAX_AVOIDANCE_STACKS)

func test_start_of_battle_resets_stacks() -> void:
	_trait._avoidance_stacks = DoubleTheFunTrait.MAX_AVOIDANCE_STACKS
	_trait.StartOfBattle(_repr)
	assert_eq(_trait._avoidance_stacks, 0)

# --- Targeting weight ---

func test_targeting_defence_multiplier_is_one_point_five() -> void:
	assert_eq(_trait.GetTargetingDefenceMultiplier(), 1.5)

func test_base_class_targeting_defence_multiplier_is_one() -> void:
	var base_trait: CharacterTrait = CharacterTrait.new()
	assert_eq(base_trait.GetTargetingDefenceMultiplier(), 1.0)
