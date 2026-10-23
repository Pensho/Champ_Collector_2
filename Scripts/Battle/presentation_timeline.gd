class_name PresentationTimeline extends RefCounted

## Holds one action's results and hands them out as its effect scene instances reach their
## impact markers, then one cascade echo at a time. View-only: the results are already
## applied. Every query returns results in their original order and returns each result at
## most once.

var _results: Array[CombatResult]
var _released: Array[bool] = []
var _effect_impact_indices: Array[int]
var _spawn_mode: SkillPresentation.Spawn_Mode
var _instance_target_IDs: Array[int]
var _final_impact: int
var _echo_brackets: Array[int] = []


## p_effect_impact_indices holds each top-level skill effect's impact_index, by effect index.
## Field_Wide takes a single instance, whose target ID is ignored. An action with no effect
## instance passes an empty p_instance_target_IDs and only queries echoes and the remainder.
func _init(
		p_results: Array[CombatResult],
		p_effect_impact_indices: Array[int] = [],
		p_spawn_mode: SkillPresentation.Spawn_Mode = SkillPresentation.Spawn_Mode.Per_Target,
		p_instance_target_IDs: Array[int] = [],
		p_impact_count: int = 1) -> void:
	_results = p_results
	_released.resize(p_results.size())
	_released.fill(false)
	_effect_impact_indices = p_effect_impact_indices
	_spawn_mode = p_spawn_mode
	_instance_target_IDs = p_instance_target_IDs
	_final_impact = maxi(p_impact_count, 1) - 1
	for index in p_results.size():
		if(CombatResult.Kind.Cascade_Triggered == p_results[index].kind):
			_echo_brackets.append(index)


func ResultsForImpact(p_instance_target_ID: int, p_impact_index: int) -> Array[CombatResult]:
	return _Release(func(p_index: int) -> bool:
		var result: CombatResult = _results[p_index]
		return (_IsImpactResult(result)
				and p_impact_index == _ImpactFor(result)
				and _InstanceFor(result) == _InstanceKey(p_instance_target_ID)))


func EchoCount() -> int:
	return _echo_brackets.size()


## Everything still held that was emitted before the echo.
func ResultsBeforeEcho(p_ordinal: int) -> Array[CombatResult]:
	var start: int = _echo_brackets[p_ordinal]
	return _Release(func(p_index: int) -> bool: return p_index < start)


## The echo's Cascade_Triggered bracket (its first result), the echo's own results, and
## anything still held that was emitted before it.
func ResultsForEcho(p_ordinal: int) -> Array[CombatResult]:
	var end: int = _EchoEnd(p_ordinal)
	return _Release(func(p_index: int) -> bool: return p_index < end)


## Everything not yet released: the Post_Cast results, plus whatever an instance that ended
## early never reached.
func RemainingResults() -> Array[CombatResult]:
	return _Release(func(_p_index: int) -> bool: return true)


func _Release(p_matches: Callable) -> Array[CombatResult]:
	var released: Array[CombatResult] = []
	for index in _results.size():
		if(not _released[index] and p_matches.call(index)):
			_released[index] = true
			released.append(_results[index])
	return released


## The index one past the echo's last result: the next bracket, or the first result back
## outside any cascade.
func _EchoEnd(p_ordinal: int) -> int:
	var index: int = _echo_brackets[p_ordinal] + 1
	while(index < _results.size()
			and CombatResult.Kind.Cascade_Triggered != _results[index].kind
			and _results[index].cascade_depth > 0):
		index += 1
	return index


func _IsImpactResult(p_result: CombatResult) -> bool:
	return (CombatResult.Presentation_Phase.Skill_Effects == p_result.phase
			and 0 == p_result.cascade_depth)


func _HasEffect(p_result: CombatResult) -> bool:
	return p_result.effect_index >= 0 and p_result.effect_index < _effect_impact_indices.size()


func _HasInstance(p_result: CombatResult) -> bool:
	return (SkillPresentation.Spawn_Mode.Field_Wide == _spawn_mode
			or _instance_target_IDs.has(p_result.target_ID))


func _ImpactFor(p_result: CombatResult) -> int:
	if(not _HasEffect(p_result)):
		return _final_impact
	return mini(_effect_impact_indices[p_result.effect_index], _final_impact)


## A result whose target has no instance travels with the final instance.
func _InstanceFor(p_result: CombatResult) -> int:
	if(_HasEffect(p_result) and _HasInstance(p_result)):
		return _InstanceKey(p_result.target_ID)
	return _InstanceKey(_instance_target_IDs.back() if not _instance_target_IDs.is_empty() else -1)


## Field_Wide has one instance, so every result keys to it.
func _InstanceKey(p_target_ID: int) -> int:
	return -1 if SkillPresentation.Spawn_Mode.Field_Wide == _spawn_mode else p_target_ID
