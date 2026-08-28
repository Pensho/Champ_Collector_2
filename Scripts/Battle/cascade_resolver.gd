class_name CascadeResolver extends RefCounted

## Owns the post-and-drain queue for Concept_Document.md 1.1.3's cascade channel: effects
## that trigger off other effects, drained after the current batch instead of recursing.
## Two tenants ride the same queue: Channel 3 Echo contributions and ordering-only deferred
## triggers (not Channel 3, despite the name). MAX_CASCADE_DEPTH bounds both; each has its
## own fan-out cap. A mechanic tagged Channel 3 in Concept_Document.md belongs on
## SubscribeCascadeContributor; SubscribeDeferredTrigger is for mechanics needing only ordering.

const MAX_CASCADE_DEPTH: int = 4
const MAX_CASCADE_INSTANCES_PER_ACTION: int = 16
const MAX_DEFERRED_TRIGGER_INSTANCES_PER_ACTION: int = 16

class DeferredTrigger:
	var mechanic_key: StringName
	var matches: Callable
	var callback: Callable

	func _init(p_mechanic_key: StringName, p_matches: Callable, p_callback: Callable) -> void:
		mechanic_key = p_mechanic_key
		matches = p_matches
		callback = p_callback

var _resolver: BattleResolver
var _deferred_triggers: Dictionary[Types.Cascade_Trigger, Array] = {}
var _contributors: Array[Callable] = []
var _contributors_by_trigger: Dictionary[Types.Cascade_Trigger, Array] = {}
var _strength_modifiers: Array[Callable] = []
var _pending: Array[CascadeEvent] = []
# Keyed "mechanic_key:subject_ID" — a trigger source fires at most once per
# originating action (Concept_Document.md 1.1.4), cleared at the action's end.
var _fired_this_action: Dictionary[String, bool] = {}
var _deferred_trigger_instances_this_action: int = 0
var _current_event_depth: int = 0


func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver

func SubscribeDeferredTrigger(
		p_trigger: Types.Cascade_Trigger,
		p_mechanic_key: StringName,
		p_matches: Callable,
		p_callback: Callable) -> void:
	if(not _deferred_triggers.has(p_trigger)):
		_deferred_triggers[p_trigger] = []
	_deferred_triggers[p_trigger].append(DeferredTrigger.new(p_mechanic_key, p_matches, p_callback))

func SubscribeCascadeContributor(p_callback: Callable, p_trigger: Variant = null) -> void:
	if(null == p_trigger):
		_contributors.append(p_callback)
		return
	if(not _contributors_by_trigger.has(p_trigger)):
		_contributors_by_trigger[p_trigger] = []
	_contributors_by_trigger[p_trigger].append(p_callback)

func SubscribeStrengthModifier(p_callback: Callable) -> void:
	_strength_modifiers.append(p_callback)

func Post(p_event: CascadeEvent) -> void:
	p_event.depth = maxi(_resolver.CurrentEchoDepth(), _current_event_depth) + 1
	if(p_event.depth > MAX_CASCADE_DEPTH):
		return
	_pending.append(p_event)


func Drain() -> void:
	while(not _pending.is_empty()):
		_ResolveEvent(_pending.pop_front())

## Clears the per-originating-action dedup set and instance counters, once the batch
## that started at BattleResolver._batch_depth 0 has fully drained.
func ResetForNextAction() -> void:
	_fired_this_action.clear()
	_deferred_trigger_instances_this_action = 0


func _ResolveEvent(p_event: CascadeEvent) -> void:
	var previous_event_depth: int = _current_event_depth
	_current_event_depth = p_event.depth
	for trigger: DeferredTrigger in _deferred_triggers.get(p_event.trigger, []):
		if(not trigger.matches.call(p_event)):
			continue
		var key: String = "%s:%d" % [trigger.mechanic_key, p_event.subject_ID]
		if(_fired_this_action.get(key, false)):
			continue
		_fired_this_action[key] = true
		if(p_event.origin_ID < 0):
			p_event.origin_ID = p_event.subject_ID
		for i in p_event.instance_count:
			if(_deferred_trigger_instances_this_action >= MAX_DEFERRED_TRIGGER_INSTANCES_PER_ACTION):
				break
			_deferred_trigger_instances_this_action += 1
			trigger.callback.call(p_event)
	_ResolveContributions(p_event)
	_current_event_depth = previous_event_depth

func _ResolveContributions(p_event: CascadeEvent) -> void:
	var extenders_allowed: bool = Types.Cascade_Trigger.Skill_Resolved == p_event.trigger
	var bases: Array[CascadeContribution] = []
	var base_keys: Array[String] = []
	var extra_instances: int = 0
	var extender_keys: Array[String] = []
	var claimed_this_call: Dictionary[String, bool] = {}
	var applicable_contributors: Array[Callable] = _contributors.duplicate()
	applicable_contributors.append_array(_contributors_by_trigger.get(p_event.trigger, []))
	for contributor: Callable in applicable_contributors:
		var contribution: CascadeContribution = contributor.call(p_event)
		if(contribution == null or contribution.instances <= 0):
			continue
		if(CascadeContribution.Kind.Extender == contribution.kind and not extenders_allowed):
			continue
		var key: String = "%s:%d" % [contribution.mechanic_key, p_event.subject_ID]
		if(_fired_this_action.get(key, false) or claimed_this_call.get(key, false)):
			continue
		claimed_this_call[key] = true
		if(CascadeContribution.Kind.Base == contribution.kind):
			bases.append(contribution)
			base_keys.append(key)
		else:
			extra_instances += contribution.instances
			extender_keys.append(key)
	if(bases.is_empty()):
		return
	for key: String in base_keys:
		_fired_this_action[key] = true
	for key: String in extender_keys:
		_fired_this_action[key] = true
	var dominant: CascadeContribution = bases[0]
	for base: CascadeContribution in bases:
		if(base.instances > dominant.instances):
			dominant = base
	dominant.instances += extra_instances
	for base: CascadeContribution in bases:
		for i in base.instances:
			p_event.origin_ID = (base.origin_for_instance.call(i) if base.origin_for_instance.is_valid()
					else p_event.subject_ID)
			if(not _resolver.BeginEchoInstance(
					base.mechanic_key, p_event.subject_ID, p_event.trigger, p_event.depth,
					_StrengthContributionsFor(p_event))):
				return
			if(base.resolve.is_valid()):
				base.resolve.call(p_event)
			else:
				_resolver.ResolveSkillEcho(
						p_event.subject_ID, p_event.skill_ID, p_event.target_IDs, base.strength_multiplier)
			p_event.mechanic_key = base.mechanic_key
			_NotifyCascadeInstanceResolved(p_event)
			_resolver.EndEchoInstance()

func _StrengthContributionsFor(p_event: CascadeEvent) -> Dictionary[StringName, float]:
	var contributions: Dictionary[StringName, float] = {}
	for modifier: Callable in _strength_modifiers:
		var strength: CascadeStrength = modifier.call(p_event)
		if(strength == null or 1.0 == strength.multiplier):
			continue
		contributions[strength.mechanic_key] = (
				contributions.get(strength.mechanic_key, 0.0) + strength.multiplier - 1.0)
	return contributions

func _NotifyCascadeInstanceResolved(p_event: CascadeEvent) -> void:
	for character_ID: int in _resolver.GetCharacters().keys():
		var character: Character = _resolver.GetCharacters()[character_ID]
		if(character._current_health <= 0):
			continue
		for active_trait: CharacterTrait in Skills.ActiveHooks(
				character, Types.Combat_Event.Cascade_Instance_Resolved):
			active_trait.OnCascadeInstanceResolved(character_ID, p_event, _resolver)

