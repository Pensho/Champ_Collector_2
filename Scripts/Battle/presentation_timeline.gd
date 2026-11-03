class_name PresentationTimeline extends RefCounted

## Holds one action's results and hands them out as its effect scene instances reach their
## impact markers, then one cascade echo at a time. View-only: the results are already
## applied. Every query returns results in their original order and returns each result at
## most once.

var _results: Array[CombatResult]
var _released: Array[bool] = []
var _effect_impact_indices: Array[int]
var _spawn_mode: SkillPresentation.Spawn_Mode
var _instance_keys: Array[int]
var _final_impact: int
var _echo_brackets: Array[int] = []


## p_effect_impact_indices holds each top-level skill effect's impact_index, by effect index.
## p_instance_keys names each instance: its target ID, or its effect index under Per_Effect.
## Field_Wide takes a single instance, whose key is ignored. An action with no effect
## instance passes an empty p_instance_keys and only queries echoes and the remainder.
func _init(
		p_results: Array[CombatResult],
		p_effect_impact_indices: Array[int] = [],
		p_spawn_mode: SkillPresentation.Spawn_Mode = SkillPresentation.Spawn_Mode.Per_Target,
		p_instance_keys: Array[int] = [],
		p_impact_count: int = 1) -> void:
	_results = p_results
	_released.resize(p_results.size())
	_released.fill(false)
	_effect_impact_indices = p_effect_impact_indices
	_spawn_mode = p_spawn_mode
	_instance_keys = p_instance_keys
	_final_impact = maxi(p_impact_count, 1) - 1
	for index in p_results.size():
		if(CombatResult.Kind.Cascade_Triggered == p_results[index].kind):
			_echo_brackets.append(index)


## Fills p_keys and p_target_IDs with one entry per effect instance: the cast targets, the first
## target alone for Field_Wide, or, for Per_Effect, each top-level effect that produced a result,
## aimed at that effect's first result.
static func PlanInstances(
		p_spawn_mode: SkillPresentation.Spawn_Mode,
		p_results: Array[CombatResult],
		p_cast_target_IDs: Array[int],
		p_keys: Array[int],
		p_target_IDs: Array[int]) -> void:
	match p_spawn_mode:
		SkillPresentation.Spawn_Mode.Field_Wide:
			p_target_IDs.append(p_cast_target_IDs[0] if not p_cast_target_IDs.is_empty() else -1)
		SkillPresentation.Spawn_Mode.Per_Effect:
			for result: CombatResult in p_results:
				if(CombatResult.Presentation_Phase.Skill_Effects == result.phase and 0 == result.cascade_depth
						and result.effect_index >= 0 and not p_keys.has(result.effect_index)):
					p_keys.append(result.effect_index)
					p_target_IDs.append(result.target_ID)
			return
		_:
			p_target_IDs.append_array(p_cast_target_IDs)
	p_keys.append_array(p_target_IDs)


## One past the first Trait_Effect result: the results before this land at once, the rest when the
## trait effect ends. 0 without a Trait_Effect.
static func TraitEffectEnd(p_results: Array[CombatResult]) -> int:
	return 1 + p_results.find_custom(func(p_result: CombatResult) -> bool:
		return CombatResult.Kind.Trait_Effect == p_result.kind)


func ResultsForImpact(p_instance_key: int, p_impact_index: int) -> Array[CombatResult]:
	return _Release(func(p_index: int) -> bool:
		var result: CombatResult = _results[p_index]
		return (_IsImpactResult(result)
				and p_impact_index == _ImpactFor(result)
				and _InstanceFor(result) == _InstanceKey(p_instance_key)))


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
			or _instance_keys.has(_ResultKey(p_result)))


func _ImpactFor(p_result: CombatResult) -> int:
	if(not _HasEffect(p_result)):
		return _final_impact
	return mini(_effect_impact_indices[p_result.effect_index], _final_impact)


## A result with no instance of its own travels with the final instance.
func _InstanceFor(p_result: CombatResult) -> int:
	if(_HasEffect(p_result) and _HasInstance(p_result)):
		return _InstanceKey(_ResultKey(p_result))
	return _InstanceKey(_instance_keys.back() if not _instance_keys.is_empty() else -1)


## The instance key a result belongs to: its effect under Per_Effect, otherwise its target.
func _ResultKey(p_result: CombatResult) -> int:
	return p_result.effect_index if SkillPresentation.Spawn_Mode.Per_Effect == _spawn_mode else p_result.target_ID


## Field_Wide has one instance, so every result keys to it.
func _InstanceKey(p_key: int) -> int:
	return -1 if SkillPresentation.Spawn_Mode.Field_Wide == _spawn_mode else p_key
