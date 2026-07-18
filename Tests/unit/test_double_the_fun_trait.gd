extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")
const VISUAL_EFFECTS_SCRIPT = preload("res://Scripts/Battle/character_visual_effects.gd")
const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _repr: CharacterRepresentation = null
var _visual_effects: CharacterVisualEffects = null
var _character: Character = null
var _trait: DoubleTheFunTrait = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_repr = double(REPR_SCRIPT).new()
	_visual_effects = double(VISUAL_EFFECTS_SCRIPT).new()
	stub(_repr, "GetVisualEffects").to_return(_visual_effects)
	_character = Character.new()
	_character._current_health = 10
	_trait = DoubleTheFunTrait.new()
	var roster: Dictionary[int, Character] = {0: _character}
	_resolver = TestFactory.make_resolver(roster, CombatSides.new([0], []))
	_InitTrait(Types.Rarity.Common)

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

func after_each() -> void:
	_repr.free()
	_visual_effects.free()

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
	_InitTrait(Types.Rarity.Legendary)
	assert_eq(_trait.GetAvoidChance(), 0.05)

func test_chance_ramps_per_stack_epic() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait._avoidance_stacks = 1
	assert_almost_eq(_trait.GetAvoidChance(), 0.10, 0.0001)
	_trait._avoidance_stacks = 2
	assert_almost_eq(_trait.GetAvoidChance(), 0.15, 0.0001)
	_trait._avoidance_stacks = 3
	assert_almost_eq(_trait.GetAvoidChance(), 0.20, 0.0001)

func test_max_chance_legendary() -> void:
	_InitTrait(Types.Rarity.Legendary)
	_trait._avoidance_stacks = DoubleTheFunTrait.MAX_AVOIDANCE_STACKS
	assert_almost_eq(_trait.GetAvoidChance(), 0.23, 0.0001)

# --- Stack ramp / cap / reset behaviour (driven via OnDamageTaken outcomes) ---

func test_stacks_increment_on_a_hit() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._avoidance_stacks = 0
	var multiplier: float = _trait.OnDamageTaken(0, _resolver)
	if multiplier == 1.0:
		assert_eq(_trait._avoidance_stacks, 1, "A hit (no avoid) should increment stacks by 1")
	else:
		assert_eq(_trait._avoidance_stacks, 0, "An avoid should reset stacks to 0")

func test_stacks_cap_at_max_after_repeated_hits() -> void:
	# Common rarity has no entry in AVOIDANCE_INCREMENT, so chance stays at the 5% base
	# regardless of stacks. Driving many calls makes repeated hits overwhelmingly likely
	# while keeping the cap assertion deterministic.
	_InitTrait(Types.Rarity.Common)
	for i in 200:
		_trait.OnDamageTaken(0, _resolver)
	assert_true(_trait._avoidance_stacks <= DoubleTheFunTrait.MAX_AVOIDANCE_STACKS)

func test_avoid_reports_trait_text() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))
	var avoided: bool = false
	for i in 500:
		_trait._avoidance_stacks = DoubleTheFunTrait.MAX_AVOIDANCE_STACKS
		if(_trait.OnDamageTaken(0, _resolver) == 0.0):
			avoided = true
			break
	assert_true(avoided, "A 23% avoid chance over 500 rolls should avoid at least once")
	var trait_texts: Array[CombatResult] = received.filter(
		func(p_result): return p_result.kind == CombatResult.Kind.Trait_Text)
	assert_eq(trait_texts.size(), 1, "The avoid should be reported exactly once")
	assert_eq(trait_texts[0].text, "Avoided!")

func test_start_of_battle_resets_stacks() -> void:
	_trait._avoidance_stacks = DoubleTheFunTrait.MAX_AVOIDANCE_STACKS
	_trait.StartOfBattle()
	assert_eq(_trait._avoidance_stacks, 0)

func test_on_death_resets_stacks() -> void:
	_trait._avoidance_stacks = DoubleTheFunTrait.MAX_AVOIDANCE_STACKS
	_trait.OnDeath()
	assert_eq(_trait._avoidance_stacks, 0)

func test_refresh_visuals_after_death_clears_sprite_echoes() -> void:
	_trait._avoidance_stacks = DoubleTheFunTrait.MAX_AVOIDANCE_STACKS
	_trait.OnDeath()
	_trait.RefreshVisuals(_repr)
	assert_call_count(_visual_effects, "SetSpriteEchoes", 1)
	assert_eq(get_call_parameters(_visual_effects, "SetSpriteEchoes", 0)[0], 0)

# --- Targeting weight ---

func test_targeting_defence_multiplier_is_one_point_five() -> void:
	assert_eq(_trait.GetTargetingDefenceMultiplier(), 1.5)

func test_base_class_targeting_defence_multiplier_is_one() -> void:
	var base_trait: CharacterTrait = CharacterTrait.new()
	assert_eq(base_trait.GetTargetingDefenceMultiplier(), 1.0)
