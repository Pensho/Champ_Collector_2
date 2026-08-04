class_name CascadeResolver extends RefCounted

## Owns cascade trigger registration and the post-and-drain queue for Concept_Document.md
## 1.1.3's cascade channel: effects that trigger off other effects. Trigger points call
## Post() and return immediately; Drain() runs the pending queue iteratively once the
## current resolution completes (BattleResolver._EndBatch, at batch depth 0), rather than
## recursing on the call stack — this is the one place both termination bounds required by
## 1.1.4 are enforced, instead of each effect being shaped safely by convention. Holds a
## back-reference to its owning BattleResolver, matching StatusEffectResolver and
## ZoneResolver.

const MAX_CASCADE_DEPTH: int = 4
const MAX_CASCADE_INSTANCES_PER_ACTION: int = 16

class Listener:
	var mechanic_key: StringName
	# Answers whether this listener's mechanic is the one behind p_event, checked before
	# any dedup or fan-out accounting — a trigger enum value (e.g. Status_Expired) is
	# shared by every status that can expire, so without this a listener for one status
	# would burn the shared fan-out budget on events that were never its own.
	var matches: Callable
	var callback: Callable

	func _init(p_mechanic_key: StringName, p_matches: Callable, p_callback: Callable) -> void:
		mechanic_key = p_mechanic_key
		matches = p_matches
		callback = p_callback

var _resolver: BattleResolver
var _listeners: Dictionary[Types.Cascade_Trigger, Array] = {}
var _pending: Array[CascadeEvent] = []
# Keyed "mechanic_key:subject_ID" — a trigger source fires at most once per
# originating action (Concept_Document.md 1.1.4), cleared at the action's end.
var _fired_this_action: Dictionary[String, bool] = {}
var _instances_this_action: int = 0
# The depth of the instance currently resolving; 0 while nothing is. Post() stamps a
# new event one level deeper than this.
var _active_depth: int = 0


func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver


## Registers p_callback to run once per instance when p_trigger fires and p_matches(event)
## is true, identified by p_mechanic_key (Concept_Document.md 1.1.3's composition-law
## currency: a buff/debuff type, trait resource, or skill effect — never character
## identity). p_callback receives the CascadeEvent and must resolve exactly one instance
## per call.
func Subscribe(
		p_trigger: Types.Cascade_Trigger,
		p_mechanic_key: StringName,
		p_matches: Callable,
		p_callback: Callable) -> void:
	if(not _listeners.has(p_trigger)):
		_listeners[p_trigger] = []
	_listeners[p_trigger].append(Listener.new(p_mechanic_key, p_matches, p_callback))


## Enqueues p_event for the next Drain. Depth is stamped here, one level deeper than
## whichever instance is currently resolving (1 for a trigger fired directly from the
## originating action) — callers never set it. A cascade past MAX_CASCADE_DEPTH is
## silently refused, per Concept_Document.md 1.1.4.
func Post(p_event: CascadeEvent) -> void:
	p_event.depth = _active_depth + 1
	if(p_event.depth > MAX_CASCADE_DEPTH):
		return
	_pending.append(p_event)


func Drain() -> void:
	while(not _pending.is_empty()):
		_ResolveEvent(_pending.pop_front())


## Clears the per-originating-action dedup set and instance counter, once the batch
## that started at BattleResolver._batch_depth 0 has fully drained.
func ResetForNextAction() -> void:
	_fired_this_action.clear()
	_instances_this_action = 0


func _ResolveEvent(p_event: CascadeEvent) -> void:
	for listener: Listener in _listeners.get(p_event.trigger, []):
		if(not listener.matches.call(p_event)):
			continue
		var key: String = "%s:%d" % [listener.mechanic_key, p_event.subject_ID]
		if(_fired_this_action.get(key, false)):
			continue
		_fired_this_action[key] = true
		var allowed: int = maxi(mini(p_event.instance_count, MAX_CASCADE_INSTANCES_PER_ACTION - _instances_this_action), 0)
		for i in allowed:
			_instances_this_action += 1
			var saved_depth: int = _active_depth
			_active_depth = p_event.depth
			_resolver._current_cascade_depth = p_event.depth
			_EmitCascadeTriggered(listener.mechanic_key, p_event)
			listener.callback.call(p_event)
			_resolver._current_cascade_depth = 0
			_active_depth = saved_depth


func _EmitCascadeTriggered(p_mechanic_key: StringName, p_event: CascadeEvent) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Cascade_Triggered)
	result.target_ID = p_event.subject_ID
	result.text = String(p_mechanic_key)
	result.cascade_trigger = p_event.trigger
	_resolver._Emit(result)
