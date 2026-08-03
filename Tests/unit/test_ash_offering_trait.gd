extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _husk_a: Character = null
var _husk_b: Character = null
var _non_husk_ally: Character = null
var _enemy: Character = null
var _trait: AshOfferingTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func _make_character(p_name: String) -> Character:
	var character: Character = Character.new()
	character._name = p_name
	character._current_health = 10
	character._attributes[Types.Attribute.Health] = 10
	return character

func before_each() -> void:
	_owner = _make_character("Ashen Oracle")
	_husk_a = _make_character("Cinder Husk")
	_husk_b = _make_character("Cinder Husk")
	_non_husk_ally = _make_character("Cinder Spitter")
	_enemy = _make_character("Champion")
	_trait = AshOfferingTrait.new()
	_trait.Init(Types.Rarity.Epic)
	_owner._trait = _trait
	_characters = {0: _owner, 1: _husk_a, 2: _husk_b, 3: _non_husk_ally, 4: _enemy}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1, 2, 3], [4]))

func test_no_ally_death_leaves_sermon_at_base_damage() -> void:
	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Cinder Sermon", {}, _resolver)

	assert_eq(result._damage_multiplier, 1.0, "No stacks means Cinder Sermon is unaffected")

func test_a_cinder_husk_death_grants_forty_percent_to_the_next_sermon() -> void:
	_trait.OnAllyDeath(0, 1, _resolver)

	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Cinder Sermon", {}, _resolver)

	assert_eq(result._damage_multiplier, 1.4, "One Husk death should grant +40%% to the next Sermon")

func test_a_non_husk_ally_death_does_not_stack() -> void:
	_trait.OnAllyDeath(0, 3, _resolver)

	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Cinder Sermon", {}, _resolver)

	assert_eq(result._damage_multiplier, 1.0, "Only a Cinder Husk death should fuel Ash Offering")

func test_multiple_husk_deaths_stack_before_being_consumed() -> void:
	_trait.OnAllyDeath(0, 1, _resolver)
	_trait.OnAllyDeath(0, 2, _resolver)

	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Cinder Sermon", {}, _resolver)

	assert_eq(result._damage_multiplier, 1.8, "Two deaths should stack to +80%%")

func test_the_bonus_is_consumed_by_the_sermon_it_boosts() -> void:
	_trait.OnAllyDeath(0, 1, _resolver)
	_trait.OnSkillCast(0, [], "Cinder Sermon", {}, _resolver)

	var second_result: TraitSkillResult = _trait.OnSkillCast(0, [], "Cinder Sermon", {}, _resolver)

	assert_eq(second_result._damage_multiplier, 1.0, "The bonus must not carry into a second Sermon")

func test_other_skills_do_not_consume_the_pending_bonus() -> void:
	_trait.OnAllyDeath(0, 1, _resolver)

	_trait.OnSkillCast(0, [], "Cinder Spit", {}, _resolver)
	var sermon_result: TraitSkillResult = _trait.OnSkillCast(0, [], "Cinder Sermon", {}, _resolver)

	assert_eq(sermon_result._damage_multiplier, 1.4, "A non-Sermon cast must not spend the pending stack")
