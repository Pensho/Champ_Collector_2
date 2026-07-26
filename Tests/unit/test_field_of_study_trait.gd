extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally: Character = null
var _enemy_a: Character = null
var _enemy_b: Character = null
var _trait: FieldOfStudyTrait = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_owner = TestFactory.make_character()
	_ally = TestFactory.make_character()
	_enemy_a = TestFactory.make_character()
	_enemy_b = TestFactory.make_character()
	for character in [_owner, _ally, _enemy_a, _enemy_b]:
		character._current_health = character._attributes[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var characters: Dictionary[int, Character] = {0: _owner, 1: _ally, 2: _enemy_a, 3: _enemy_b}
	_resolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], [2, 3]))
	_trait = FieldOfStudyTrait.new()
	_owner._trait = _trait

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

func _debuff_template(p_type: Types.Debuff_Type, p_duration: int, p_source_ID: int) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	debuff.source_ID = p_source_ID
	return debuff

# --- Rarity table ---

func test_weakness_reduction_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.04,
		Types.Rarity.Rare: 0.06,
		Types.Rarity.Epic: 0.08,
		Types.Rarity.Legendary: 0.10,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(FieldOfStudyTrait.GetWeaknessReduction(rarity), expected[rarity],
			"WEAKNESS_REDUCTION at %s" % Types.RarityName(rarity))

# --- Weakness identification ---

func test_start_of_battle_picks_the_highest_non_health_primary_attribute() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	# make_character(): Attack 8 is the unique highest among the primary attributes
	# (Attack 8, Defence 6, Accuracy 7, Resistance 6, Mysticism 4, Knowledge 4);
	# CritChance 5 and CritDamage 150 must be excluded as they are not primary attributes.
	_trait.StartOfBattle(0, _resolver)

	assert_eq(_trait._weakness_by_enemy[2], Types.Attribute.Attack)
	assert_eq(_trait._weakness_by_enemy[3], Types.Attribute.Attack)

func test_start_of_battle_excludes_speed_even_when_it_is_highest() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_enemy_a._attributes[Types.Attribute.Speed] = 999

	_trait.StartOfBattle(0, _resolver)

	assert_eq(_trait._weakness_by_enemy[2], Types.Attribute.Attack,
		"Speed must never be identified as the weakness, even when it is the highest attribute")

func test_start_of_battle_tie_resolves_to_one_of_the_tied_attributes() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_enemy_a._attributes[Types.Attribute.Attack] = 8
	_enemy_a._attributes[Types.Attribute.Accuracy] = 8

	_trait.StartOfBattle(0, _resolver)

	var identified: Types.Attribute = _trait._weakness_by_enemy[2]
	assert_true(identified == Types.Attribute.Attack or identified == Types.Attribute.Accuracy,
		"A tie must resolve to one of the tied attributes")

func test_start_of_battle_ignores_dead_enemies() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_enemy_b._current_health = 0

	_trait.StartOfBattle(0, _resolver)

	assert_true(_trait._weakness_by_enemy.has(2))
	assert_false(_trait._weakness_by_enemy.has(3), "A dead enemy must not have a weakness identified")

# --- Applying a debuff carries the Studied Weakness rider ---

func test_applying_a_debuff_on_a_studied_enemy_stamps_the_weakness_rider() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.StartOfBattle(0, _resolver)

	_resolver.ApplyDebuff(2, _debuff_template(Types.Debuff_Type.Enfeeble, 3, 0))

	assert_eq(_enemy_a._active_debuffs.size(), 1, "The rider must ride the triggering debuff, not add a second one")
	var applied: StatusEffects.Debuff = _enemy_a._active_debuffs[0]
	assert_true(applied.has_weakness_rider)
	assert_eq(applied.weakness_attribute, _trait._weakness_by_enemy[2])
	assert_almost_eq(applied.weakness_reduction, FieldOfStudyTrait.GetWeaknessReduction(Types.Rarity.Epic), 0.0001)

func test_debuff_on_an_unstudied_target_gets_no_rider() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.StartOfBattle(0, _resolver)

	# The ally was never a studied enemy, so it is absent from _weakness_by_enemy.
	_resolver.ApplyDebuff(1, _debuff_template(Types.Debuff_Type.Enfeeble, 3, 0))

	var applied: StatusEffects.Debuff = _ally._active_debuffs[0]
	assert_false(applied.has_weakness_rider, "A debuff on an unstudied target must get no rider")

func test_each_debuff_on_a_studied_enemy_carries_its_own_rider() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.StartOfBattle(0, _resolver)
	_resolver.ApplyDebuff(2, _debuff_template(Types.Debuff_Type.Enfeeble, 2, 0))

	_resolver.ApplyDebuff(2, _debuff_template(Types.Debuff_Type.Blind, 5, 0))

	assert_eq(_enemy_a._active_debuffs.size(), 2)
	for applied: StatusEffects.Debuff in _enemy_a._active_debuffs:
		assert_true(applied.has_weakness_rider)
		assert_eq(applied.weakness_attribute, _trait._weakness_by_enemy[2])
		assert_almost_eq(applied.weakness_reduction, FieldOfStudyTrait.GetWeaknessReduction(Types.Rarity.Epic), 0.0001)

# --- The reduction actually lowers the identified attribute on a snapshot ---

func test_weakness_rider_reduces_the_identified_attribute_on_a_target_snapshot() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.StartOfBattle(0, _resolver)
	_resolver.ApplyDebuff(2, _debuff_template(Types.Debuff_Type.Enfeeble, 3, 0))
	var identified: Types.Attribute = _trait._weakness_by_enemy[2]

	var attrs: Dictionary[Types.Attribute, int] = {identified: 100}
	Skills.TriggerTargetDebuffs(_enemy_a, attrs)

	assert_eq(attrs[identified], 92, "Epic Studied Weakness should reduce the identified attribute by 8%%")

func test_two_riders_on_the_same_attribute_compound() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.StartOfBattle(0, _resolver)
	_resolver.ApplyDebuff(2, _debuff_template(Types.Debuff_Type.Enfeeble, 2, 0))
	_resolver.ApplyDebuff(2, _debuff_template(Types.Debuff_Type.Blind, 5, 0))
	var identified: Types.Attribute = _trait._weakness_by_enemy[2]

	var attrs: Dictionary[Types.Attribute, int] = {identified: 100}
	Skills.TriggerTargetDebuffs(_enemy_a, attrs)

	# Two independent 8% riders compound sequentially: 100 -> 92 -> 84.
	assert_eq(attrs[identified], 84,
		"Two simultaneous Scholar debuffs on the same enemy each carry their own rider")
