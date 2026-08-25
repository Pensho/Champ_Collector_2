class_name CascadeResolver extends RefCounted

## Owns cascade trigger registration and the post-and-drain queue for Concept_Document.md
## 1.1.3's cascade channel: effects that trigger off other effects. Trigger points call
## Post() and return immediately; Drain() runs the pending queue iteratively once the
## current resolution completes (BattleResolver._EndBatch, at batch depth 0), rather than
## recursing on the call stack. Concept_Document.md 1.1.4's two termination bounds are
## enforced on every Echo path, not only this one: Post() refuses past MAX_CASCADE_DEPTH,
## and BattleResolver.BeginEchoInstance — the single choke point this class and the
## trait-local repeat loops that bypass it all call — refuses past
## MAX_CASCADE_INSTANCES_PER_ACTION. Holds a back-reference to its owning BattleResolver,
## matching StatusEffectResolver and ZoneResolver.

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
# (CascadeEvent, StringName) -> int: extra instances to add to whichever listener just
# matched (identified by its own mechanic_key), summed before the per-instance loop's
# bound is computed (e.g. the Herald of the Loom's Black Thread, the Sorcerer's Echo
# charges). Modifiers amplify an existing match; they never create one.
var _instance_modifiers: Array[Callable] = []
var _pending: Array[CascadeEvent] = []
# Keyed "mechanic_key:subject_ID" — a trigger source fires at most once per
# originating action (Concept_Document.md 1.1.4), cleared at the action's end.
var _fired_this_action: Dictionary[String, bool] = {}


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


## Registers p_callback to amplify a listener's instance count once it has already
## matched an event (e.g. the Herald of the Loom's Black Thread granting one extra
## instance to a cascade instance caused by its own action, or the Sorcerer's Echo
## charges scoped to its own mechanic_key). p_callback receives the CascadeEvent and the
## matched listener's mechanic_key, and returns the extra instance count to add (0 for
## no effect).
func SubscribeInstanceModifier(p_callback: Callable) -> void:
	_instance_modifiers.append(p_callback)


## Enqueues p_event for the next Drain. Depth is stamped here, one level deeper than
## whichever instance is currently resolving (1 for a trigger fired directly from the
## originating action) — callers never set it. A cascade past MAX_CASCADE_DEPTH is
## silently refused, per Concept_Document.md 1.1.4.
func Post(p_event: CascadeEvent) -> void:
	p_event.depth = _resolver.CurrentEchoDepth() + 1
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


func _ResolveEvent(p_event: CascadeEvent) -> void:
	for listener: Listener in _listeners.get(p_event.trigger, []):
		if(not listener.matches.call(p_event)):
			continue
		var key: String = "%s:%d" % [listener.mechanic_key, p_event.subject_ID]
		if(_fired_this_action.get(key, false)):
			continue
		_fired_this_action[key] = true
		var extra_instances: int = 0
		for modifier: Callable in _instance_modifiers:
			extra_instances += int(modifier.call(p_event, listener.mechanic_key))
		var requested: int = maxi(p_event.instance_count + extra_instances, 0)
		for i in requested:
			if(not _resolver.BeginEchoInstance(
					listener.mechanic_key, p_event.subject_ID, p_event.trigger, p_event.depth)):
				break
			listener.callback.call(p_event)
			_NotifyCascadeInstanceResolved(p_event)
			_resolver.EndEchoInstance()


## Notifies every living character's trait that a real cascade instance (one loop
## iteration of a matched listener, not merely a posted event) resolved, so a passive
## can react to instance count itself (e.g. the Herald of the Loom's Golden Thread).
func _NotifyCascadeInstanceResolved(p_event: CascadeEvent) -> void:
	for character_ID: int in _resolver.GetCharacters().keys():
		var character: Character = _resolver.GetCharacters()[character_ID]
		if(character._current_health <= 0):
			continue
		for active_trait: CharacterTrait in Skills.ActiveHooks(
				character, Types.Combat_Event.Cascade_Instance_Resolved):
			active_trait.OnCascadeInstanceResolved(character_ID, p_event, _resolver)

