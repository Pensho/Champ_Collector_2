extends GutTest

# PresentationTimeline routes one action's results to the effect scene instance and impact
# marker that release them, then hands out cascades and the post-cast remainder.

const FIRST_TARGET: int = 3
const SECOND_TARGET: int = 4
const CASTER: int = 0

const PER_TARGET: SkillPresentation.Spawn_Mode = SkillPresentation.Spawn_Mode.Per_Target
const STAGGERED: SkillPresentation.Spawn_Mode = SkillPresentation.Spawn_Mode.Per_Target_Staggered
const FIELD_WIDE: SkillPresentation.Spawn_Mode = SkillPresentation.Spawn_Mode.Field_Wide

func _result(
		p_target_ID: int,
		p_effect_index: int,
		p_phase: CombatResult.Presentation_Phase = CombatResult.Presentation_Phase.Skill_Effects,
		p_cascade_depth: int = 0,
		p_kind: CombatResult.Kind = CombatResult.Kind.Damage) -> CombatResult:
	var result: CombatResult = CombatResult.new(p_kind)
	result.target_ID = p_target_ID
	result.effect_index = p_effect_index
	result.phase = p_phase
	result.cascade_depth = p_cascade_depth
	return result

func _timeline(
		p_results: Array[CombatResult],
		p_effect_impact_indices: Array[int] = [],
		p_spawn_mode: SkillPresentation.Spawn_Mode = PER_TARGET,
		p_instance_target_IDs: Array[int] = [],
		p_impact_count: int = 1) -> PresentationTimeline:
	return PresentationTimeline.new(
			p_results, p_effect_impact_indices, p_spawn_mode, p_instance_target_IDs, p_impact_count)

func test_results_go_to_their_targets_instance_and_effects_impact() -> void:
	var first_hit: CombatResult = _result(FIRST_TARGET, 0)
	var second_hit: CombatResult = _result(FIRST_TARGET, 1)
	var timeline: PresentationTimeline = _timeline(
			[first_hit, second_hit], [0, 1], PER_TARGET, [FIRST_TARGET], 2)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [first_hit])
	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 1), [second_hit])

func test_per_target_instances_only_release_their_own_target() -> void:
	var first_hit: CombatResult = _result(FIRST_TARGET, 0)
	var second_hit: CombatResult = _result(SECOND_TARGET, 0)
	var timeline: PresentationTimeline = _timeline(
			[first_hit, second_hit], [0], PER_TARGET, [FIRST_TARGET, SECOND_TARGET], 1)

	assert_eq(timeline.ResultsForImpact(SECOND_TARGET, 0), [second_hit])
	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [first_hit])

func test_staggered_instances_route_like_per_target() -> void:
	var first_hit: CombatResult = _result(FIRST_TARGET, 0)
	var second_hit: CombatResult = _result(SECOND_TARGET, 0)
	var timeline: PresentationTimeline = _timeline(
			[first_hit, second_hit], [0], STAGGERED, [FIRST_TARGET, SECOND_TARGET], 1)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [first_hit])
	assert_eq(timeline.ResultsForImpact(SECOND_TARGET, 0), [second_hit])

func test_field_wide_releases_every_target_on_its_single_instance() -> void:
	var first_hit: CombatResult = _result(FIRST_TARGET, 0)
	var second_hit: CombatResult = _result(SECOND_TARGET, 0)
	var timeline: PresentationTimeline = _timeline(
			[first_hit, second_hit], [0], FIELD_WIDE, [FIRST_TARGET], 1)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [first_hit, second_hit])

func test_an_impact_past_the_last_marker_counts_as_the_last_marker() -> void:
	var late_hit: CombatResult = _result(FIRST_TARGET, 0)
	var timeline: PresentationTimeline = _timeline([late_hit], [5], PER_TARGET, [FIRST_TARGET], 2)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [])
	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 1), [late_hit])

func test_a_target_without_an_instance_lands_at_its_effects_impact_on_the_final_instance() -> void:
	var soaked_hit: CombatResult = _result(CASTER, 0)
	var timeline: PresentationTimeline = _timeline(
			[soaked_hit], [0], PER_TARGET, [FIRST_TARGET, SECOND_TARGET], 2)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [])
	assert_eq(timeline.ResultsForImpact(SECOND_TARGET, 0), [soaked_hit])

func test_results_outside_any_effect_go_with_the_final_impact_of_the_final_instance() -> void:
	var trait_text: CombatResult = _result(FIRST_TARGET, -1, CombatResult.Presentation_Phase.Skill_Effects, 0,
			CombatResult.Kind.Trait_Text)
	var timeline: PresentationTimeline = _timeline(
			[trait_text], [0], PER_TARGET, [FIRST_TARGET, SECOND_TARGET], 2)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 1), [])
	assert_eq(timeline.ResultsForImpact(SECOND_TARGET, 0), [])
	assert_eq(timeline.ResultsForImpact(SECOND_TARGET, 1), [trait_text])

func _bracket(p_depth: int = 1) -> CombatResult:
	return _result(FIRST_TARGET, 0, CombatResult.Presentation_Phase.Skill_Effects, p_depth,
			CombatResult.Kind.Cascade_Triggered)

func _echo_hit(p_depth: int = 1) -> CombatResult:
	return _result(FIRST_TARGET, 0, CombatResult.Presentation_Phase.Skill_Effects, p_depth)

func test_cascade_results_are_not_released_on_an_impact() -> void:
	var hit: CombatResult = _result(FIRST_TARGET, 0)
	var timeline: PresentationTimeline = _timeline(
			[hit, _bracket(), _echo_hit()], [0], PER_TARGET, [FIRST_TARGET], 1)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [hit])

func test_each_echo_releases_its_bracket_and_its_own_results() -> void:
	var hit: CombatResult = _result(FIRST_TARGET, 0)
	var first_bracket: CombatResult = _bracket()
	var first_echo: CombatResult = _echo_hit()
	var second_bracket: CombatResult = _bracket()
	var second_echo: CombatResult = _echo_hit()
	var timeline: PresentationTimeline = _timeline(
			[hit, first_bracket, first_echo, second_bracket, second_echo], [0], PER_TARGET, [FIRST_TARGET], 1)
	timeline.ResultsForImpact(FIRST_TARGET, 0)

	assert_eq(timeline.EchoCount(), 2)
	assert_eq(timeline.ResultsForEcho(0), [first_bracket, first_echo])
	assert_eq(timeline.ResultsForEcho(1), [second_bracket, second_echo])

func test_a_nested_echo_is_its_own_echo() -> void:
	var outer_bracket: CombatResult = _bracket(1)
	var inner_bracket: CombatResult = _bracket(2)
	var inner_echo: CombatResult = _echo_hit(2)
	var timeline: PresentationTimeline = _timeline([outer_bracket, inner_bracket, inner_echo])

	assert_eq(timeline.EchoCount(), 2)
	assert_eq(timeline.ResultsForEcho(0), [outer_bracket])
	assert_eq(timeline.ResultsForEcho(1), [inner_bracket, inner_echo])

func test_an_echo_ends_where_results_return_outside_the_cascade() -> void:
	var bracket: CombatResult = _bracket()
	var echo: CombatResult = _echo_hit()
	var tick: CombatResult = _result(FIRST_TARGET, -1, CombatResult.Presentation_Phase.Post_Cast)
	var timeline: PresentationTimeline = _timeline([bracket, echo, tick])

	assert_eq(timeline.ResultsForEcho(0), [bracket, echo])
	assert_eq(timeline.RemainingResults(), [tick])

func test_results_before_an_echo_release_without_it() -> void:
	var tick: CombatResult = _result(FIRST_TARGET, -1, CombatResult.Presentation_Phase.Post_Cast)
	var bracket: CombatResult = _bracket()
	var echo: CombatResult = _echo_hit()
	var timeline: PresentationTimeline = _timeline([tick, bracket, echo])

	assert_eq(timeline.ResultsBeforeEcho(0), [tick])
	assert_eq(timeline.ResultsForEcho(0), [bracket, echo])

func test_an_echo_first_releases_held_results_emitted_before_it() -> void:
	var tick: CombatResult = _result(FIRST_TARGET, -1, CombatResult.Presentation_Phase.Post_Cast)
	var bracket: CombatResult = _bracket()
	var echo: CombatResult = _echo_hit()
	var timeline: PresentationTimeline = _timeline([tick, bracket, echo])

	assert_eq(timeline.ResultsForEcho(0), [tick, bracket, echo])

func test_queries_preserve_the_original_order() -> void:
	var first: CombatResult = _result(FIRST_TARGET, 1)
	var second: CombatResult = _result(FIRST_TARGET, 0)
	var third: CombatResult = _result(FIRST_TARGET, 1)
	var timeline: PresentationTimeline = _timeline(
			[first, second, third], [0, 0], PER_TARGET, [FIRST_TARGET], 1)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [first, second, third])

func test_post_cast_results_are_only_released_as_the_remainder() -> void:
	var hit: CombatResult = _result(FIRST_TARGET, 0)
	var tick: CombatResult = _result(FIRST_TARGET, -1, CombatResult.Presentation_Phase.Post_Cast)
	var timeline: PresentationTimeline = _timeline([hit, tick], [0], PER_TARGET, [FIRST_TARGET], 1)

	assert_eq(timeline.ResultsForImpact(FIRST_TARGET, 0), [hit])
	assert_eq(timeline.EchoCount(), 0)
	assert_eq(timeline.RemainingResults(), [tick])

func test_a_deadline_flush_after_partial_release_returns_only_the_unreleased_results() -> void:
	var first_hit: CombatResult = _result(FIRST_TARGET, 0)
	var second_hit: CombatResult = _result(FIRST_TARGET, 1)
	var echo: CombatResult = _result(FIRST_TARGET, 1, CombatResult.Presentation_Phase.Skill_Effects, 1)
	var tick: CombatResult = _result(FIRST_TARGET, -1, CombatResult.Presentation_Phase.Post_Cast)
	var timeline: PresentationTimeline = _timeline(
			[first_hit, second_hit, echo, tick], [0, 1], PER_TARGET, [FIRST_TARGET], 2)

	timeline.ResultsForImpact(FIRST_TARGET, 0)

	assert_eq(timeline.RemainingResults(), [second_hit, echo, tick])
	assert_eq(timeline.RemainingResults(), [], "Each result is released once")
