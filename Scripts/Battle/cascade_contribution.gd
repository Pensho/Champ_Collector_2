class_name CascadeContribution extends RefCounted

## A Channel 3 contribution to a cascade (Concept_Document.md 1.1.3/1.1.4), returned by a
## callback registered with CascadeResolver.SubscribeCascadeContributor. A Base creates a
## cascade where the action had none; an Extender adds Echoes to a cascade a Base already
## created and contributes nothing on its own. Null, or an instances count of 0 or less,
## means the mechanic does not apply to this event.

enum Kind { Base, Extender }

var mechanic_key: StringName
var instances: int = 0
var strength_multiplier: float = 1.0
var kind: Kind = Kind.Base
## (CascadeEvent) -> void. An unset Callable means the canonical skill replay
## (BattleResolver.ResolveSkillEcho).
var resolve: Callable
## (int instance_index) -> int: the instance's producer, if it differs from p_event.subject_ID.
var origin_for_instance: Callable


func _init(
		p_mechanic_key: StringName,
		p_instances: int,
		p_kind: Kind = Kind.Base,
		p_strength_multiplier: float = 1.0,
		p_resolve: Callable = Callable()) -> void:
	mechanic_key = p_mechanic_key
	instances = p_instances
	kind = p_kind
	strength_multiplier = p_strength_multiplier
	resolve = p_resolve
