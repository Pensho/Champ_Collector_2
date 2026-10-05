extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for boss phase 2: once a hit leaves a phased character alive at or below 50% max
# Health, its phase 2 skills and trait replace the current ones; the transition never caps
# damage (Concept_Document.md 5.3).

class RecordingTrait extends CharacterTrait:
	var start_of_battle_calls: int = 0

	func _init() -> void:
		_execution_steps = {Types.Combat_Event.Start_Combat: StartOfBattle}

	func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
		start_of_battle_calls += 1

const BOSS_ID: int = 3

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _max_health: int = 0

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_max_health = _resolver.GetMaxHealth(BOSS_ID)
	_roster[BOSS_ID]._current_health = _max_health

func _skill(p_name: String, p_cooldown_left: int = 0) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = p_name
	skill.cooldown_left = p_cooldown_left
	return skill

func _make_phased(p_phase_two_trait: CharacterTrait = RecordingTrait.new()) -> void:
	var boss: Character = _roster[BOSS_ID]
	boss._skills = [_skill("Size Up", 2)]
	boss._phase_two_skills = [_skill("Size Up"), _skill("Cash In")]
	boss._phase_two_trait = p_phase_two_trait

func _skill_names(p_character: Character) -> Array[String]:
	var names: Array[String] = []
	for skill: Skill in p_character._skills:
		names.append(skill.name)
	return names

func _phase_changed_count(p_results: Array[CombatResult]) -> int:
	return p_results.filter(
			func(result: CombatResult) -> bool: return CombatResult.Kind.Phase_Changed == result.kind).size()

func _hit(p_amount: int) -> Array[CombatResult]:
	_resolver._BeginBatch()
	_resolver._ApplyHealthLoss(BOSS_ID, p_amount, 0)
	return _resolver._EndBatch()

func test_crossing_half_health_swaps_skills_and_trait() -> void:
	_make_phased()
	var results: Array[CombatResult] = _hit(_max_health / 2)
	var boss: Character = _roster[BOSS_ID]
	assert_true(boss._in_phase_two)
	assert_eq(_skill_names(boss), ["Size Up", "Cash In"] as Array[String])
	assert_true(boss._trait is RecordingTrait, "The phase 2 trait should replace the current one")
	assert_eq((boss._trait as RecordingTrait).start_of_battle_calls, 1, "The new trait's StartOfBattle should run")
	assert_eq(_phase_changed_count(results), 1)

func test_the_transition_announces_the_bosses_own_text() -> void:
	_make_phased()
	_roster[BOSS_ID]._phase_two_text = "Cash on the table!"
	var results: Array[CombatResult] = _hit(_max_health / 2)
	var changed: Array = results.filter(
			func(result: CombatResult) -> bool: return CombatResult.Kind.Phase_Changed == result.kind)
	assert_eq(changed[0].text, "Cash on the table!")

func test_staying_above_half_health_does_not_transition() -> void:
	_make_phased()
	_hit(_max_health / 2 - 1)
	assert_false(_roster[BOSS_ID]._in_phase_two)
	assert_eq(_skill_names(_roster[BOSS_ID]), ["Size Up"] as Array[String])

func test_the_transition_fires_only_once() -> void:
	_make_phased()
	_hit(_max_health / 2)
	var phase_two_trait: CharacterTrait = _roster[BOSS_ID]._trait
	var results: Array[CombatResult] = _hit(1)
	assert_eq(_phase_changed_count(results), 0, "A later hit below 50% must not transition again")
	assert_eq(_roster[BOSS_ID]._trait, phase_two_trait, "The phase 2 trait should not be swapped again")

func test_a_lethal_hit_from_above_half_kills_without_transition() -> void:
	_make_phased()
	var results: Array[CombatResult] = _hit(_max_health * 2)
	assert_eq(_roster[BOSS_ID]._current_health, 0, "The transition must never cap damage")
	assert_false(_roster[BOSS_ID]._in_phase_two)
	assert_eq(_phase_changed_count(results), 0)

func test_a_shared_skill_keeps_its_cooldown() -> void:
	_make_phased()
	_hit(_max_health / 2)
	var skills: Array[Skill] = _roster[BOSS_ID]._skills
	assert_eq(skills[0].cooldown_left, 2, "Size Up is in both kits, so its cooldown carries over")
	assert_eq(skills[1].cooldown_left, 0, "Cash In is new and starts ready")

func test_a_transition_mid_cast_puts_the_cooldown_on_the_cast_skill() -> void:
	var boss: Character = _roster[BOSS_ID]
	var cash_in: Skill = _skill("Cash In")
	cash_in.cooldown = 4
	boss._skills = [cash_in, _skill("Size Up")]
	var phase_two_cash_in: Skill = _skill("Cash In")
	phase_two_cash_in.cooldown = 4
	boss._phase_two_skills = [_skill("Size Up"), phase_two_cash_in]
	boss._current_health = _max_health / 2 + 1
	var burning: StatusEffects.Debuff = StatusEffects.Debuff.new()
	burning.type = Types.Debuff_Type.Burning
	burning.duration = 3
	burning.source_ID = 0
	boss._active_debuffs.append(burning)
	_resolver.ResolveSkill(BOSS_ID, [0], 0)
	assert_true(boss._in_phase_two, "Sanity check: the Burning tick should trigger the transition")
	assert_eq(boss._skills[0].cooldown_left, 0, "Size Up was not cast")
	assert_eq(boss._skills[1].cooldown_left, 4, "Cash In was cast, so its phase 2 version goes on cooldown")

func test_a_null_phase_two_trait_keeps_the_current_trait() -> void:
	var current_trait: CharacterTrait = RecordingTrait.new()
	_roster[BOSS_ID]._trait = current_trait
	_make_phased(null)
	_hit(_max_health / 2)
	assert_true(_roster[BOSS_ID]._in_phase_two)
	assert_eq(_roster[BOSS_ID]._trait, current_trait)

func test_non_phased_characters_never_transition() -> void:
	var results: Array[CombatResult] = _hit(_max_health / 2 + 1)
	assert_false(_roster[BOSS_ID]._in_phase_two)
	assert_eq(_phase_changed_count(results), 0)

func test_a_preset_carries_its_phase_two_kit_into_the_character() -> void:
	var preset: CharacterPreset = CharacterPreset.new()
	preset._skills = [_skill("Size Up")]
	preset._phase_two_skills = [_skill("Cash In")]
	var character: Character = Character.new()
	character.InstantiateNew(preset, 7)
	assert_true(character.HasPhaseTwo())
	assert_ne(character._phase_two_skills[0], preset._phase_two_skills[0],
			"Each character should own its phase 2 skill instances")
