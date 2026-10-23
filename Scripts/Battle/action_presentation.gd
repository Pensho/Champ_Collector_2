class_name ActionPresentation extends RefCounted

## Plays one action's held results: starts its effect instances, releases each impact's
## results as an instance reaches its marker, then the cascade one echo at a time, then the
## rest. Battle supplies how results are shown and how the caster lunges, and advances it
## every frame.

class InstanceStart:
	var archetype: PackedScene
	var variant: EffectVariant
	var target_ID: int = -1
	var origin: Vector2
	var caster_position: Vector2
	var target_position: Vector2
	var delay: float = 0.0

var _timeline: PresentationTimeline
var _layer: BattleEffectLayer
## (Array[CombatResult]) -> void
var _present: Callable
var _lunge: Callable
var _pending: Array[InstanceStart] = []
var _playing: Array[SkillEffectScene] = []
var _connections: Dictionary[SkillEffectScene, Array] = {}
var _final_target_ID: int = -1
var _final_impact: int = 0
var _lunged: bool = false
var _echoes_started: bool = false
var _next_echo: int = 0
var _echo_timer: float = 0.0
var _done: bool = false


## With no p_starts, the results before the first echo are presented at once.
func _init(
		p_timeline: PresentationTimeline,
		p_starts: Array[InstanceStart],
		p_impact_count: int,
		p_layer: BattleEffectLayer,
		p_present: Callable,
		p_lunge: Callable = Callable()) -> void:
	_timeline = p_timeline
	_pending = p_starts.duplicate()
	_layer = p_layer
	_present = p_present
	_lunge = p_lunge
	_final_impact = maxi(p_impact_count, 1) - 1
	if(not p_starts.is_empty()):
		_final_target_ID = p_starts.back().target_ID
		return
	if(_timeline.EchoCount() > 0):
		_Present(_timeline.ResultsBeforeEcho(0))
	_StartEchoes()


func Advance(p_delta: float) -> void:
	if(_done):
		return
	for start: InstanceStart in _pending.duplicate():
		start.delay -= p_delta
		if(start.delay <= 0.0):
			_pending.erase(start)
			_Start(start)
	if(not _echoes_started and _pending.is_empty() and _playing.is_empty()):
		_StartEchoes()
	if(_echoes_started and _next_echo < _timeline.EchoCount()):
		_echo_timer -= p_delta
		if(_echo_timer <= 0.0):
			_Present(_timeline.ResultsForEcho(_next_echo))
			_next_echo += 1
			_echo_timer = BurstPacing.DelayForStep(_next_echo + 1)
	if(_echoes_started and _next_echo >= _timeline.EchoCount()
			and _pending.is_empty() and _playing.is_empty()):
		_Present(_timeline.RemainingResults())
		_done = true


func IsDone() -> bool:
	return _done


## The presentation deadline: stops every instance and presents everything still held.
func Flush() -> void:
	for instance: SkillEffectScene in _playing.duplicate():
		_Release(instance)
		instance.Stop()
	_pending.clear()
	_Present(_timeline.RemainingResults())
	_done = true


func _Start(p_start: InstanceStart) -> void:
	var instance: SkillEffectScene = _layer.Peek(p_start.archetype)
	if(null == instance):
		return
	var on_impact: Callable = func(p_index: int) -> void: _OnImpact(p_start.target_ID, p_index)
	var on_finished: Callable = func() -> void: _OnFinished(instance, p_start.target_ID)
	instance.impact_reached.connect(on_impact)
	instance.lunge_requested.connect(_OnLunge)
	instance.finished.connect(on_finished)
	_connections[instance] = [on_impact, on_finished]
	_playing.append(instance)
	instance.Play(p_start.origin, p_start.caster_position, p_start.target_position, p_start.variant)


func _OnImpact(p_target_ID: int, p_index: int) -> void:
	_Present(_timeline.ResultsForImpact(p_target_ID, p_index))
	if(p_target_ID == _final_target_ID and p_index >= _final_impact):
		_StartEchoes()


func _OnLunge() -> void:
	if(not _lunged and _lunge.is_valid()):
		_lunge.call()
	_lunged = true


func _OnFinished(p_instance: SkillEffectScene, p_target_ID: int) -> void:
	_Release(p_instance)
	if(p_target_ID == _final_target_ID):
		_StartEchoes()


func _Release(p_instance: SkillEffectScene) -> void:
	var callables: Array = _connections.get(p_instance, [])
	if(callables.size() == 2):
		p_instance.impact_reached.disconnect(callables[0])
		p_instance.finished.disconnect(callables[1])
	p_instance.lunge_requested.disconnect(_OnLunge)
	_connections.erase(p_instance)
	_playing.erase(p_instance)


func _StartEchoes() -> void:
	if(_echoes_started):
		return
	_echoes_started = true
	_echo_timer = BurstPacing.DelayForStep(1)


func _Present(p_results: Array[CombatResult]) -> void:
	if(not p_results.is_empty()):
		_present.call(p_results)
