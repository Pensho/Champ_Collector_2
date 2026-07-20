extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _enemy: Character = null
var _trait: StrikeTheFlawTrait = null

func before_each() -> void:
	_owner = Character.new()
	_enemy = Character.new()
	_owner._current_health = 10
	_enemy._current_health = 10
	_trait = StrikeTheFlawTrait.new()

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_owner._rarity = p_rarity
	_trait.Init(p_rarity)

# --- Rarity table ---

func test_cracked_facet_duration_table() -> void:
	var expected: Dictionary[Types.Rarity, int] = {
		Types.Rarity.Uncommon: 1,
		Types.Rarity.Rare: 1,
		Types.Rarity.Epic: 2,
		Types.Rarity.Legendary: 2,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(StrikeTheFlawTrait.GetCrackedFacetDuration(rarity), expected[rarity],
			"CRACKED_FACET_DURATION at %s" % Types.RarityName(rarity))

# --- Direct hook behavior ---

func test_on_critical_hit_applies_cracked_facet_with_low_rarity_duration() -> void:
	var characters: Dictionary[int, Character] = {0: _owner, 1: _enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	_InitTrait(Types.Rarity.Uncommon)

	_trait.OnCriticalHit(0, 1, resolver)

	assert_eq(_enemy._active_debuffs.size(), 1)
	assert_eq(_enemy._active_debuffs[0].type, Types.Debuff_Type.Cracked_Facet)
	assert_eq(_enemy._active_debuffs[0].duration, 1)
	assert_eq(_enemy._active_debuffs[0].source_ID, 0)

func test_on_critical_hit_applies_cracked_facet_with_high_rarity_duration() -> void:
	var characters: Dictionary[int, Character] = {0: _owner, 1: _enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	_InitTrait(Types.Rarity.Legendary)

	_trait.OnCriticalHit(0, 1, resolver)

	assert_eq(_enemy._active_debuffs[0].duration, 2)

# --- Resolver integration: hook only fires on a landed critical hit ---

func test_critical_hit_through_the_resolver_applies_cracked_facet() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._trait = StrikeTheFlawTrait.new()
	roster[0]._trait.Init(Types.Rarity.Uncommon)
	roster[0]._attributes[Types.Attribute.CritChance] = 100
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveTraitDamage(0, [3], resolver.GetCombatAttributes(0), {Types.Attribute.Attack: 1.0}, true)

	assert_eq(roster[3]._active_debuffs.size(), 1, "A guaranteed crit should apply Cracked Facet")
	assert_eq(roster[3]._active_debuffs[0].type, Types.Debuff_Type.Cracked_Facet)

func test_non_critical_hit_applies_no_debuff() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._trait = StrikeTheFlawTrait.new()
	roster[0]._trait.Init(Types.Rarity.Uncommon)
	roster[0]._attributes[Types.Attribute.CritChance] = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveTraitDamage(0, [3], resolver.GetCombatAttributes(0), {Types.Attribute.Attack: 1.0}, true)

	assert_eq(roster[3]._active_debuffs.size(), 0, "A non-critical hit should not apply Cracked Facet")

func test_hook_does_not_fire_when_critical_hits_are_disallowed() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._trait = StrikeTheFlawTrait.new()
	roster[0]._trait.Init(Types.Rarity.Uncommon)
	roster[0]._attributes[Types.Attribute.CritChance] = 100
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveTraitDamage(0, [3], resolver.GetCombatAttributes(0), {Types.Attribute.Attack: 1.0}, false)

	assert_eq(roster[3]._active_debuffs.size(), 0,
		"Cracked Facet should not be applied when the damage source disallows critical hits")
