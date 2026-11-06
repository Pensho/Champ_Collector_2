extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Slab Tossers (Encounter_Design_Document.md 2.2): each Slab Toss flips the slab
# on a chance roll Hexed biases. The good side adds one Echo; the bad side weakens the hit and
# Hexes the tosser for a turn. The flip's effect plays ahead of the hit.

const SLAB_TOSS_TRAIT: SlabTossTrait = preload("res://Data/Character_Traits/Enemy_Traits/Slab_Toss_Trait.tres")
const SLAB_TOSS: Skill = preload("res://Data/Character_Skill_Variants/Attack_Skills/Slab_Toss.tres")
const TOSSER_ID: int = 3
const TARGET_ID: int = 0
const TOSSES: int = 2000

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _trait: SlabTossTrait = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_trait = SLAB_TOSS_TRAIT.duplicate(true)
	_trait.Init(Types.Rarity.Common)
	_roster[TOSSER_ID]._trait = _trait
	_roster[TOSSER_ID]._skills = [SLAB_TOSS]
	_trait.StartOfBattle(TOSSER_ID, _resolver)

func _toss() -> TraitSkillResult:
	return _trait.OnSkillCast(TOSSER_ID, [TARGET_ID], SlabTossTrait.TOSS_SKILL_NAME,
			_resolver.GetEffectiveAttributes(TOSSER_ID), _resolver)

func _holds_hexed() -> bool:
	return _roster[TOSSER_ID]._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Hexed == debuff.type)

func _hex_the_tosser() -> void:
	var hexed: StatusEffects.Debuff = StatusEffects.Debuff.new()
	hexed.type = Types.Debuff_Type.Hexed
	hexed.duration = 99
	_roster[TOSSER_ID]._active_debuffs.append(hexed)

func _good_side_share() -> float:
	var good_sides: int = 0
	for toss in TOSSES:
		if(1.0 == _toss()._damage_multiplier):
			good_sides += 1
		_roster[TOSSER_ID]._active_debuffs = _roster[TOSSER_ID]._active_debuffs.filter(
				func(debuff: StatusEffects.Debuff) -> bool: return debuff.duration > 1)
	return float(good_sides) / TOSSES

func _target_hits(p_results: Array[CombatResult]) -> int:
	return p_results.filter(func(result: CombatResult) -> bool:
		return CombatResult.Kind.Damage == result.kind and TARGET_ID == result.target_ID).size()

func test_a_good_side_adds_an_echo() -> void:
	_trait._good_side_chance = 1.0
	assert_eq(_target_hits(_resolver.ResolveSkill(TOSSER_ID, [TARGET_ID], 0)), 2)
	assert_false(_holds_hexed())

func test_a_bad_side_lands_one_weakened_hit() -> void:
	_trait._good_side_chance = 0.0
	assert_eq(_toss()._damage_multiplier, _trait._bad_side_damage_multiplier)
	assert_eq(_target_hits(_resolver.ResolveSkill(TOSSER_ID, [TARGET_ID], 0)), 1)

func test_a_bad_side_hexes_the_tosser_for_a_turn() -> void:
	_trait._good_side_chance = 0.0
	_resolver.ResolveSkill(TOSSER_ID, [TARGET_ID], 0)
	assert_true(_holds_hexed())
	assert_eq(_roster[TOSSER_ID]._active_debuffs[0].duration, 1)

func test_a_bad_side_while_hexed_restarts_the_hexed() -> void:
	_trait._good_side_chance = 0.0
	_resolver.BeginTurn(TOSSER_ID)
	_resolver.ResolveSkill(TOSSER_ID, [TARGET_ID], 0)
	_resolver.GetStatusResolver().TickStatusDurations(TOSSER_ID)
	_resolver.BeginTurn(TOSSER_ID)
	_resolver.ResolveSkill(TOSSER_ID, [TARGET_ID], 0)
	_resolver.GetStatusResolver().TickStatusDurations(TOSSER_ID)
	assert_true(_holds_hexed(), "The second bad side's Hexed should outlast the turn it lands on")

func test_the_good_side_lands_about_half_the_time() -> void:
	assert_almost_eq(_good_side_share(), 0.5, 0.05)

func test_hexed_turns_most_tosses_bad() -> void:
	_hex_the_tosser()
	assert_almost_eq(_good_side_share(), 0.25, 0.05)

func test_the_flip_plays_ahead_of_the_hit() -> void:
	var effect: CombatResult = PresentationTimeline.CastTraitEffect(_resolver.ResolveSkill(TOSSER_ID, [TARGET_ID], 0))
	assert_not_null(effect)
	assert_true(effect.visual_scene in [SlabTossTrait.GOOD_SIDE_SCENE, SlabTossTrait.BAD_SIDE_SCENE])

func test_other_skills_do_not_toss() -> void:
	_roster[TOSSER_ID]._skills = [TestFactory.make_strike_skill()]
	var results: Array[CombatResult] = _resolver.ResolveSkill(TOSSER_ID, [TARGET_ID], 0)
	assert_null(PresentationTimeline.CastTraitEffect(results))
	assert_eq(_target_hits(results), 1)
