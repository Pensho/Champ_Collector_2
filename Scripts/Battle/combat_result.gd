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
	Trait_Text,
	Death,
	Heal,
	Zone_Cleared,
	Turn_Bar_Reset_Pending,
	Attack_Missed,
	Debuff_Blocked,
	Barrier_Absorbed,
}

var kind: Kind
var source_ID: int = -1
var target_ID: int = -1
var amount: int = 0
var critical: bool = false
var fraction: float = 0.0
var status_ID: int = -1
var status_IDs: Array[int] = []
var is_buff: bool = false
var buff_type: Types.Buff_Type = Types.Buff_Type.Invalid
var debuff_type: Types.Debuff_Type = Types.Debuff_Type.Invalid
var duration: int = 0
var text: String = ""
var color: Color = Color.WHITE
var zone_ID: int = -1
var skill_type: Types.Skill_Type
var amount_by_source: Dictionary[int, int] = {}


func _init(p_kind: Kind) -> void:
	kind = p_kind
