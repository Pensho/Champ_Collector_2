class_name CombatResult extends RefCounted


enum Kind {
	Damage,
	Debuff_Tick,
	Debuff_Resisted,
	Status_Applied,
	Status_Duration,
	Statuses_Removed,
	Statuses_Cleared,
	Turn_Bar_Bump,
	Zone_Placed,
	Zone_Triggered,
	Zone_Charges_Changed,
	Trait_Text,
	Death,
	Heal,
	Zone_Cleared,
	Turn_Bar_Reset_Pending,
	Attack_Missed,
	Debuff_Blocked,
	Barrier_Absorbed,
	Turn_Skipped,
	Status_Effect_Denied,
	Cascade_Triggered,
	Phase_Changed,
}

enum Presentation_Phase {
	Skill_Effects,
	Post_Cast,
}

const NO_HEALTH_SNAPSHOT: int = -1

var kind: Kind
var source_ID: int = -1
var target_ID: int = -1
var amount: int = 0
var critical: bool = false
var fraction: float = 0.0
var status_ID: int = -1
## Cascade_Triggered: the caster's skill index a skill echo repeats; -1 otherwise.
var skill_ID: int = -1
var status_IDs: Array[int] = []
var is_buff: bool = false
var buff_type: Types.Buff_Type = Types.Buff_Type.Invalid
var debuff_type: Types.Debuff_Type = Types.Debuff_Type.Invalid
var duration: int = 0
var stacks: int = 0
var text: String = ""
var color: Color = Color.WHITE
var zone_ID: int = -1
var charges: int = 0
var visual_scene: PackedScene
var amount_by_source: Dictionary[int, int] = {}
var combined_damage_modifier: CombinedDamageModifier = null
var cascade_depth: int = 0
var cascade_trigger: Types.Cascade_Trigger = Types.Cascade_Trigger.Status_Expired
var phase: Presentation_Phase = Presentation_Phase.Post_Cast
## The top-level Skill.effects index resolving when this result was emitted; -1 outside one.
var effect_index: int = -1
## The target's Health as it stood right after this result, so the view can show each hit's own state.
var target_health_after: int = NO_HEALTH_SNAPSHOT
var target_max_health_after: int = NO_HEALTH_SNAPSHOT
## The statuses whose own damage or heal this result is (a tick, Mana Burn, Overflow), so the
## battle view can play their effects.
var triggered_by: Array[StatusEffectData] = []


func _init(p_kind: Kind) -> void:
	kind = p_kind
