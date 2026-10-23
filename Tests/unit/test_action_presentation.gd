extends GutTest

# ActionPresentation's release order: impact results as an instance reaches its marker,
# echoes one at a time after the final impact, the remainder once everything has finished,
# and a deadline flush. Instance signals are emitted by hand rather than by animation.

const TARGET: int = 3
const OTHER_TARGET: int = 4

var _layer: BattleEffectLayer
var _archetype: PackedScene
var _presented: Array[CombatResult] = []
var _lunges: int = 0

func before_each() -> void:
	_presented.clear()
	_lunges = 0
	_layer = BattleEffectLayer.new()
	add_child_autofree(_layer)
	_archetype = _make_archetype()
	_layer.Reserve(_archetype, 2)

func _make_archetype() -> PackedScene:
	var root: SkillEffectScene = SkillEffectScene.new()
	var player: AnimationPlayer = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	var animation: Animation = Animation.new()
	animation.length = 1.0
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(&"effect", animation)
	player.add_animation_library(&"", library)
	root.add_child(player)
	player.owner = root
	root.animation_player = player
	var scene: PackedScene = PackedScene.new()
	scene.pack(root)
	root.free()
	return scene

func _result(p_target_ID: int, p_cascade_depth: int = 0,
		p_kind: CombatResult.Kind = CombatResult.Kind.Damage,
		p_phase: CombatResult.Presentation_Phase = CombatResult.Presentation_Phase.Skill_Effects) -> CombatResult:
	var result: CombatResult = CombatResult.new(p_kind)
	result.target_ID = p_target_ID
	result.effect_index = 0
	result.cascade_depth = p_cascade_depth
	result.phase = p_phase
	return result

func _start(p_target_ID: int, p_delay: float = 0.0) -> ActionPresentation.InstanceStart:
	var start: ActionPresentation.InstanceStart = ActionPresentation.InstanceStart.new()
	start.archetype = _archetype
	start.target_ID = p_target_ID
	start.delay = p_delay
	return start

func _presentation(p_results: Array[CombatResult], p_starts: Array[ActionPresentation.InstanceStart],
		p_targets: Array[int]) -> ActionPresentation:
	var timeline: PresentationTimeline = PresentationTimeline.new(
			p_results, [0], SkillPresentation.Spawn_Mode.Per_Target, p_targets, 1)
	return ActionPresentation.new(timeline, p_starts, 1, _layer,
			func(p_released: Array[CombatResult]) -> void: _presented.append_array(p_released),
			func() -> void: _lunges += 1)

func _playing_instances() -> Array[SkillEffectScene]:
	var playing: Array[SkillEffectScene] = []
	for child: Node in _layer.get_children():
		if((child as SkillEffectScene).visible):
			playing.append(child)
	return playing

func test_impact_results_wait_for_the_marker() -> void:
	var hit: CombatResult = _result(TARGET)
	var presentation: ActionPresentation = _presentation([hit], [_start(TARGET)], [TARGET])
	presentation.Advance(0.0)
	assert_eq(_presented, [], "Nothing lands before the impact marker")

	_playing_instances()[0].impact_reached.emit(0)

	assert_eq(_presented, [hit])

func test_echoes_release_one_at_a_time_after_the_final_impact_then_the_rest() -> void:
	var hit: CombatResult = _result(TARGET)
	var first_bracket: CombatResult = _result(TARGET, 1, CombatResult.Kind.Cascade_Triggered)
	var second_bracket: CombatResult = _result(TARGET, 1, CombatResult.Kind.Cascade_Triggered)
	var tick: CombatResult = _result(TARGET, 0, CombatResult.Kind.Status_Duration,
			CombatResult.Presentation_Phase.Post_Cast)
	var presentation: ActionPresentation = _presentation(
			[hit, first_bracket, second_bracket, tick], [_start(TARGET)], [TARGET])
	presentation.Advance(0.0)
	var instance: SkillEffectScene = _playing_instances()[0]

	instance.impact_reached.emit(0)
	presentation.Advance(BurstPacing.DelayForStep(1))
	assert_eq(_presented, [hit, first_bracket], "The first echo follows the final impact")

	presentation.Advance(BurstPacing.DelayForStep(2))
	assert_eq(_presented, [hit, first_bracket, second_bracket])
	assert_false(presentation.IsDone(), "The instance is still playing")

	instance.finished.emit()
	presentation.Advance(0.0)
	assert_eq(_presented, [hit, first_bracket, second_bracket, tick])
	assert_true(presentation.IsDone())

func test_without_instances_the_results_before_the_first_echo_land_at_once() -> void:
	var tick: CombatResult = _result(TARGET, 0, CombatResult.Kind.Debuff_Tick,
			CombatResult.Presentation_Phase.Post_Cast)
	var bracket: CombatResult = _result(TARGET, 1, CombatResult.Kind.Cascade_Triggered)
	var starts: Array[ActionPresentation.InstanceStart] = []
	var presentation: ActionPresentation = _presentation([tick, bracket], starts, [])

	assert_eq(_presented, [tick])
	presentation.Advance(BurstPacing.DelayForStep(1))
	presentation.Advance(0.0)
	assert_eq(_presented, [tick, bracket])
	assert_true(presentation.IsDone())

func test_a_staggered_instance_starts_after_its_delay() -> void:
	var presentation: ActionPresentation = _presentation(
			[_result(TARGET), _result(OTHER_TARGET)], [_start(TARGET), _start(OTHER_TARGET, 0.3)],
			[TARGET, OTHER_TARGET])
	presentation.Advance(0.1)
	assert_eq(_playing_instances().size(), 1)
	presentation.Advance(0.25)
	assert_eq(_playing_instances().size(), 2)

func test_only_the_first_lunge_moves_the_caster() -> void:
	var presentation: ActionPresentation = _presentation(
			[_result(TARGET), _result(OTHER_TARGET)], [_start(TARGET), _start(OTHER_TARGET)],
			[TARGET, OTHER_TARGET])
	presentation.Advance(0.0)
	for instance: SkillEffectScene in _playing_instances():
		instance.lunge_requested.emit()
	assert_eq(_lunges, 1)

func test_a_flush_stops_the_instances_and_presents_everything_held() -> void:
	var hit: CombatResult = _result(TARGET)
	var presentation: ActionPresentation = _presentation([hit], [_start(TARGET)], [TARGET])
	presentation.Advance(0.0)

	presentation.Flush()

	assert_eq(_presented, [hit])
	assert_true(presentation.IsDone())
	assert_eq(_playing_instances().size(), 0)
