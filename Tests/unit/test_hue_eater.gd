extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Hue-Eater (Encounter_Design_Document.md 2.2): Translucent cuts every Health
# loss unless she holds Hexed; Prismatic Rain's beams hit, pass through her, or bend into her
# while Hexed; Gathered Light fills a slice a turn, hovers when full and launches next turn;
# Enfeeble landing on her is consumed for slices; in phase 2, landed beams add slices; her luck
# line follows three Prismatic Rains cast in a row without Hexed on her, once per battle.

const HUE_EATER_TRAIT: HueEaterTrait = preload("res://Data/Character_Traits/Enemy_Traits/Hue_Eater_Trait.tres")
const BOSS_ID: int = 3
const PARTY_IDS: Array[int] = [0, 1, 2]

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _trait: HueEaterTrait = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_trait = _install_trait(_roster, _resolver)

func _install_trait(p_roster: Dictionary[int, Character], p_resolver: BattleResolver) -> HueEaterTrait:
	var hue_eater_trait: HueEaterTrait = HUE_EATER_TRAIT.duplicate(true)
	hue_eater_trait.Init(Types.Rarity.Common)
	p_roster[BOSS_ID]._trait = hue_eater_trait
	hue_eater_trait.StartOfBattle(BOSS_ID, p_resolver)
	return hue_eater_trait

func _debuff(p_type: Types.Debuff_Type, p_duration: int = 2) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	debuff.source_ID = 0
	return debuff

func _hex_the_boss() -> void:
	_roster[BOSS_ID]._active_debuffs.append(_debuff(Types.Debuff_Type.Hexed, 5))

func _health_loss(p_amount: int) -> int:
	var before: int = _roster[BOSS_ID]._current_health
	_resolver._BeginBatch()
	_resolver._ApplyHealthLoss(BOSS_ID, p_amount, 0)
	_resolver._EndBatch()
	return before - _roster[BOSS_ID]._current_health

func _beam_skill(p_hit_chance: float, p_beams: int = 1) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Prismatic Rain"
	skill.target = Types.Skill_Target.All_Enemies
	skill.cooldown = 2
	for index in p_beams:
		var beam: PrismaticBeamEffect = PrismaticBeamEffect.new()
		beam.damage_scaling = {Types.Attribute.Mysticism: 1.0}
		beam.hit_chance = p_hit_chance
		skill.effects.append(beam)
	return skill

func _cast(p_skill: Skill) -> Array[CombatResult]:
	_roster[BOSS_ID]._skills = [p_skill]
	return _resolver.ResolveSkill(BOSS_ID, PARTY_IDS, 0)

func _party_health() -> Array[int]:
	var health: Array[int] = []
	for party_ID in PARTY_IDS:
		health.append(_roster[party_ID]._current_health)
	return health

func _party_damaged(p_before: Array[int]) -> int:
	var count: int = 0
	for index in PARTY_IDS.size():
		if(_roster[PARTY_IDS[index]]._current_health < p_before[index]):
			count += 1
	return count

func _is_pass_through_text(p_result: CombatResult) -> bool:
	return (CombatResult.Kind.Trait_Text == p_result.kind
			and PrismaticBeamEffect.PASSES_THROUGH_TEXT == p_result.text)

func _start_turns(p_count: int) -> void:
	for turn in p_count:
		_resolver.BeginTurn(BOSS_ID)

func test_translucent_cuts_health_loss_to_a_quarter() -> void:
	assert_eq(_health_loss(100), 25)

func test_hexed_lifts_translucent() -> void:
	_hex_the_boss()
	assert_eq(_health_loss(100), 100)

func test_translucent_also_cuts_damage_over_time() -> void:
	var plain_roster: Dictionary[int, Character] = {}
	plain_roster.assign(TestFactory.make_full_roster())
	var plain_resolver: BattleResolver = TestFactory.make_resolver(plain_roster, TestFactory.make_full_sides())
	for roster: Dictionary[int, Character] in [_roster, plain_roster]:
		roster[BOSS_ID]._active_debuffs.append(_debuff(Types.Debuff_Type.Burning))
	var translucent_before: int = _roster[BOSS_ID]._current_health
	var plain_before: int = plain_roster[BOSS_ID]._current_health
	_resolver.BeginTurn(BOSS_ID)
	plain_resolver.BeginTurn(BOSS_ID)
	var plain_tick: int = plain_before - plain_roster[BOSS_ID]._current_health
	assert_gt(plain_tick, 0, "Sanity check: Burning should tick on an unprotected boss")
	assert_eq(translucent_before - _roster[BOSS_ID]._current_health, int(floor(plain_tick * 0.25)))

func test_translucent_cuts_a_plague_tick_to_a_quarter() -> void:
	var plague: StatusEffects.Debuff = _debuff(Types.Debuff_Type.Plague, 3)
	plague.value = 100.0
	_roster[BOSS_ID]._active_debuffs.append(plague)
	var before: int = _roster[BOSS_ID]._current_health
	_resolver.BeginTurn(BOSS_ID)
	assert_eq(before - _roster[BOSS_ID]._current_health, 25)

func test_a_beam_that_rolls_a_hit_strikes_one_champion() -> void:
	var before: Array[int] = _party_health()
	var boss_health: int = _roster[BOSS_ID]._current_health
	_cast(_beam_skill(1.0))
	assert_eq(_party_damaged(before), 1)
	assert_eq(_roster[BOSS_ID]._current_health, boss_health)

func test_a_bent_beam_passes_through_a_translucent_caster() -> void:
	var before: Array[int] = _party_health()
	var boss_health: int = _roster[BOSS_ID]._current_health
	var results: Array[CombatResult] = _cast(_beam_skill(0.0))
	assert_eq(_party_damaged(before), 0)
	assert_eq(_roster[BOSS_ID]._current_health, boss_health)
	assert_true(results.any(_is_pass_through_text))

func test_a_bent_beam_hits_a_hexed_caster() -> void:
	_hex_the_boss()
	var before: Array[int] = _party_health()
	var boss_health: int = _roster[BOSS_ID]._current_health
	_cast(_beam_skill(0.0))
	assert_eq(_party_damaged(before), 0)
	assert_lt(_roster[BOSS_ID]._current_health, boss_health)

func test_gathered_light_gains_a_slice_each_turn() -> void:
	_start_turns(3)
	assert_eq(_trait.GetParts(), 3)

func test_a_full_hexagon_hovers_a_turn_then_launches_at_the_party() -> void:
	_start_turns(6)
	assert_eq(_trait.GetParts(), 6)
	var before: Array[int] = _party_health()
	_start_turns(1)
	assert_eq(_trait.GetParts(), 0, "The launch empties the hexagon")
	assert_eq(_party_damaged(before), PARTY_IDS.size(), "The launch hits every champion")

func test_the_launch_effect_precedes_the_launch_damage() -> void:
	_start_turns(6)
	var results: Array[CombatResult] = _resolver.BeginTurn(BOSS_ID)
	var split: int = PresentationTimeline.TraitEffectEnd(results)
	assert_gt(split, 0, "The launch should emit its trait effect")
	assert_false(results.slice(0, split).any(
			func(result: CombatResult) -> bool: return CombatResult.Kind.Damage == result.kind),
			"No launch damage may land before the hexagon flies")

func test_the_hexagon_does_not_launch_before_it_is_full() -> void:
	var before: Array[int] = _party_health()
	_start_turns(6)
	assert_eq(_party_damaged(before), 0)

func test_an_enfeeble_landing_on_her_is_consumed_for_two_slices() -> void:
	_start_turns(4)
	_resolver.GetStatusResolver().ApplyDebuff(BOSS_ID, _debuff(Types.Debuff_Type.Enfeeble))
	assert_eq(_trait.GetParts(), 2)
	assert_false(_roster[BOSS_ID]._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Enfeeble == debuff.type),
			"The Enfeeble should be consumed")

func test_an_enfeeble_never_takes_the_hexagon_below_empty() -> void:
	_start_turns(1)
	_resolver.GetStatusResolver().ApplyDebuff(BOSS_ID, _debuff(Types.Debuff_Type.Enfeeble))
	assert_eq(_trait.GetParts(), 0)

func test_a_resisted_enfeeble_removes_no_slices() -> void:
	_start_turns(4)
	_roster[0]._attributes[Types.Attribute.Accuracy] = 1
	_roster[BOSS_ID]._attributes[Types.Attribute.Resistance] = 1000
	_resolver.GetStatusResolver().CastDebuff(BOSS_ID, _debuff(Types.Debuff_Type.Enfeeble), 0)
	assert_eq(_trait.GetParts(), 4)

func test_in_phase_two_each_landed_beam_adds_a_slice() -> void:
	_roster[BOSS_ID]._in_phase_two = true
	_cast(_beam_skill(1.0, 3))
	assert_eq(_trait.GetParts(), 3)

func test_landed_beams_add_no_slices_before_phase_two() -> void:
	_cast(_beam_skill(1.0, 3))
	assert_eq(_trait.GetParts(), 0)

func test_beam_fed_slices_stop_at_a_full_hexagon() -> void:
	_roster[BOSS_ID]._in_phase_two = true
	_start_turns(4)
	_cast(_beam_skill(1.0, 5))
	assert_eq(_trait.GetParts(), 6)

func test_her_basic_attack_adds_no_slices_in_phase_two() -> void:
	_roster[BOSS_ID]._in_phase_two = true
	_roster[BOSS_ID]._skills = [TestFactory.make_strike_skill()]
	_resolver.ResolveSkill(BOSS_ID, [0], 0)
	assert_eq(_trait.GetParts(), 0)

func test_beams_bent_into_her_add_no_slices_in_phase_two() -> void:
	_roster[BOSS_ID]._in_phase_two = true
	_hex_the_boss()
	_cast(_beam_skill(0.0, 3))
	assert_eq(_trait.GetParts(), 0)

func test_the_hexagon_carries_through_the_phase_two_transition() -> void:
	var boss: Character = _roster[BOSS_ID]
	boss._phase_two_skills = [_beam_skill(0.6)]
	_start_turns(3)
	_hex_the_boss()
	_health_loss(floori(boss._current_health * 0.5) + 1)
	assert_true(boss._in_phase_two, "Sanity check: the hit should cross half Health")
	assert_eq(boss._trait, _trait, "Her trait is kept through the transition")
	assert_eq(_trait.GetParts(), 3)

func _luck_lines(p_results: Array[CombatResult]) -> int:
	return p_results.filter(func(result: CombatResult) -> bool:
		return CombatResult.Kind.Trait_Text == result.kind and HueEaterTrait.LUCK_LINE == result.text).size()

func _rains(p_count: int) -> int:
	var lines: int = 0
	for cast in p_count:
		lines += _luck_lines(_cast(_beam_skill(1.0)))
	return lines

func test_the_luck_line_follows_the_third_rain_without_hexed() -> void:
	assert_eq(_rains(2), 0)
	assert_eq(_rains(1), 1)

func test_the_luck_line_is_spoken_once_per_battle() -> void:
	assert_eq(_rains(6), 1)

func test_a_rain_cast_while_hexed_restarts_the_count() -> void:
	_rains(2)
	_hex_the_boss()
	_rains(1)
	_roster[BOSS_ID]._active_debuffs.clear()
	assert_eq(_rains(2), 0)
	assert_eq(_rains(1), 1)

func test_basic_attacks_leave_the_count_alone() -> void:
	_rains(2)
	_roster[BOSS_ID]._skills = [TestFactory.make_strike_skill()]
	_resolver.ResolveSkill(BOSS_ID, [0], 0)
	assert_eq(_rains(1), 1)
