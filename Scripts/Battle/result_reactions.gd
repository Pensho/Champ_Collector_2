class_name ResultReactions extends Resource

## The shared reaction table: every character reacts the same way to a hit, a heal, a death
## or a status landing. Their own hurt and death cues play on top.

@export var damage: ResultReaction
@export var heal: ResultReaction
@export var death: ResultReaction
@export var buff_applied: ResultReaction
@export var debuff_applied: ResultReaction


## Null when the result kind has no reaction.
func ReactionFor(p_result: CombatResult) -> ResultReaction:
	match p_result.kind:
		CombatResult.Kind.Damage, CombatResult.Kind.Debuff_Tick:
			return damage if p_result.amount > 0 else null
		CombatResult.Kind.Heal:
			return heal if p_result.amount > 0 else null
		CombatResult.Kind.Death:
			return death
		CombatResult.Kind.Status_Applied:
			return buff_applied if p_result.is_buff else debuff_applied
	return null


## The target's own non-verbal cue for this result, or null.
static func VocalCueFor(p_result: CombatResult, p_target: Character) -> SoundCue:
	match p_result.kind:
		CombatResult.Kind.Damage, CombatResult.Kind.Debuff_Tick:
			return p_target._hurt_cue if p_result.amount > 0 else null
		CombatResult.Kind.Death:
			return p_target._death_cue
	return null
