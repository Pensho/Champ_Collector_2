class_name CombatResult extends RefCounted

## One resolved combat fact ("X took 12 damage", "Y gained Empower for 2 turns",
## "Z bumped +15% on the turn bar"), produced by BattleResolver and rendered by the
## battle scene. Pure data: a kind plus the fields that kind uses; never touches nodes.

enum Kind {
	# target_ID lost `amount` health from source_ID; `critical` marks a critical strike.
	Damage,
	# target_ID lost `amount` total health to Burning; `amount_by_source` splits the
	# ticks per applying character for post-battle damage attribution.
	Burning_Tick,
	# target_ID resisted a debuff cast by source_ID.
	Debuff_Resisted,
	# target_ID gained the status `status_ID`: `is_buff`, `buff_type`/`debuff_type`,
	# `duration`, and `text` as the display name (empty for silent applications).
	Status_Applied,
	# status_ID on target_ID now has `duration` turns left (refresh or tick-down).
	Status_Duration,
	# The statuses in `status_IDs` on target_ID expired or were removed.
	Statuses_Removed,
	# Every status on target_ID was wiped (death).
	Statuses_Cleared,
	# target_ID moved by `fraction` of the turn bar (positive is forward).
	Turn_Bar_Bump,
	# source_ID placed zone `zone_ID` of `skill_type` with `duration` charges.
	Zone_Placed,
	# Zone `zone_ID` triggered on target_ID; `duration` charges remain (0 = expired).
	Zone_Triggered,
	# Trait flavor text over target_ID ("Stole buff!", "Avoided!"), colored `color`.
	Trait_Text,
	# target_ID died.
	Death,
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
