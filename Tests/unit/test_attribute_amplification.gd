extends GutTest

## Exercises the Scholar's Field of Study passive (Role_Kit_Design.md 9.14): every
## attribute modification the passive's own side applies is amplified extra percentage
## points, stamped as an &"attribute_amplification" trait_riders entry at apply time.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _scholar: Character = null
var _ally: Character = null
var _enemy: Character = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_scholar = TestFactory.make_character()
	_ally = TestFactory.make_character()
	_enemy = TestFactory.make_character()
	for character in [_scholar, _ally, _enemy]:
		character._current_health = character._attributes[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var characters: Dictionary[int, Character] = {0: _scholar, 1: _ally, 2: _enemy}
	_resolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], [2]))
	_scholar._trait = FieldOfStudyTrait.new()
	_scholar._trait.Init(Types.Rarity.Legendary)

func _enfeeble(p_source_ID: int, p_trait_riders: Dictionary[StringName, Variant] = {}) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.duration = 3
	debuff.source_ID = p_source_ID
	debuff.trait_riders = p_trait_riders
	return debuff

# make_character()'s Attack is 8: Enfeeble's own -30%% is ceil(8*0.3)=3 unamplified,
# ceil(8*0.41)=4 amplified 11 percentage points (Legendary Field of Study).

func test_a_teammate_debuff_is_amplified_by_the_scholars_own_side() -> void:
	_resolver.GetStatusResolver().ApplyDebuff(2, _enfeeble(1))

	assert_eq(_resolver.GetEffectiveAttributes(2)[Types.Attribute.Attack], 4)

func test_an_enemy_side_debuff_is_not_amplified() -> void:
	_resolver.GetStatusResolver().ApplyDebuff(1, _enfeeble(2))

	assert_eq(_resolver.GetEffectiveAttributes(1)[Types.Attribute.Attack], 5)

func test_crit_attributes_are_never_amplified() -> void:
	var keen_edge: StatusEffects.Buff = StatusEffects.Buff.new()
	keen_edge.type = Types.Buff_Type.Keen_Edge
	keen_edge.duration = 3
	keen_edge.source_ID = 1
	keen_edge.value = 20.0
	_resolver.GetStatusResolver().ApplyBuff(1, keen_edge)

	# AttributePercentagePointAdd is a flat add (+20), untouched by the percentage-based
	# amplification regardless of the applier's side.
	assert_eq(_resolver.GetEffectiveAttributes(1)[Types.Attribute.CritChance],
			_ally._attributes[Types.Attribute.CritChance] + 20)

func test_two_amplifying_teammates_take_the_highest_not_the_sum() -> void:
	_ally._trait = FieldOfStudyTrait.new()
	_ally._trait.Init(Types.Rarity.Uncommon)

	assert_almost_eq(
			Skills.AppliedAttributeAmplification(0, _resolver.GetCharacters(), _resolver.GetSides()),
			0.11, 0.0001, "The Uncommon ally must not add onto the Legendary Scholar's own amplification")

func test_amplification_survives_a_refresh() -> void:
	_resolver.GetStatusResolver().ApplyDebuff(2, _enfeeble(1))
	assert_eq(_resolver.GetEffectiveAttributes(2)[Types.Attribute.Attack], 4)

	_resolver.GetStatusResolver().ApplyDebuff(2, _enfeeble(1))

	assert_eq(_enemy._active_debuffs.size(), 1, "Enfeeble is not stackable, so the second cast refreshes")
	assert_eq(_resolver.GetEffectiveAttributes(2)[Types.Attribute.Attack], 4,
			"The refreshed instance must still carry the amplification")

func test_stamping_does_not_mutate_the_callers_own_trait_riders_dictionary() -> void:
	var shared_riders: Dictionary[StringName, Variant] = {}
	_resolver.GetStatusResolver().ApplyDebuff(2, _enfeeble(1, shared_riders))

	assert_false(shared_riders.has(&"attribute_amplification"),
			"The stamp must land on a duplicated dictionary, not the caster's own shared trait_riders")

# --- The displayed {percent}/{value} description tokens read the amplified fraction too ---

func _applied_result(p_results: Array) -> CombatResult:
	for result: CombatResult in p_results:
		if(CombatResult.Kind.Status_Applied == result.kind):
			return result
	return null

func test_the_displayed_fraction_on_a_teammates_debuff_is_amplified() -> void:
	var results: Array = _resolver.GetStatusResolver().ApplyDebuff(2, _enfeeble(1))

	assert_almost_eq(_applied_result(results).fraction, 0.41, 0.0001,
		"Sharp_Rebuttal.tres-style {percent} tokens must read Enfeeble's own amplified 41%, not 30%")

func test_the_displayed_fraction_on_an_enemy_side_debuff_is_not_amplified() -> void:
	var results: Array = _resolver.GetStatusResolver().ApplyDebuff(1, _enfeeble(2))

	assert_almost_eq(_applied_result(results).fraction, 0.3, 0.0001)

func test_the_displayed_fraction_on_a_teammates_buff_is_amplified() -> void:
	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	fortify.source_ID = 1

	var results: Array = _resolver.GetStatusResolver().ApplyBuff(2, fortify)

	assert_almost_eq(_applied_result(results).fraction, 0.41, 0.0001)

func test_vigors_max_health_percent_is_amplified_and_displayed() -> void:
	var vigor: StatusEffects.Buff = StatusEffects.Buff.new()
	vigor.type = Types.Buff_Type.Vigor
	vigor.duration = 3
	vigor.source_ID = 1

	var results: Array = _resolver.GetStatusResolver().ApplyBuff(2, vigor)

	assert_almost_eq(_applied_result(results).fraction, 0.41, 0.0001,
		"Vigor is a MaxHealthAttributePercent kind, outside ApplyAttributeModifiers, and needs its own gate")

func test_the_displayed_fraction_on_a_crit_attribute_buff_is_not_amplified() -> void:
	var keen_edge: StatusEffects.Buff = StatusEffects.Buff.new()
	keen_edge.type = Types.Buff_Type.Keen_Edge
	keen_edge.duration = 3
	keen_edge.source_ID = 1
	keen_edge.value = 20.0

	var results: Array = _resolver.GetStatusResolver().ApplyBuff(1, keen_edge)

	assert_almost_eq(_applied_result(results).fraction, 20.0, 0.0001)
