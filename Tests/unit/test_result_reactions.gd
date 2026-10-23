extends GutTest

# Each presented result picks its row from the shared reaction table, and the target's own
# hurt or death cue.

var _reactions: ResultReactions

func before_each() -> void:
	_reactions = ResultReactions.new()
	_reactions.damage = ResultReaction.new()
	_reactions.heal = ResultReaction.new()
	_reactions.death = ResultReaction.new()

func _result(p_kind: CombatResult.Kind, p_amount: int = 0) -> CombatResult:
	var result: CombatResult = CombatResult.new(p_kind)
	result.amount = p_amount
	return result

func test_hits_and_ticks_with_an_amount_use_the_damage_row() -> void:
	assert_eq(_reactions.ReactionFor(_result(CombatResult.Kind.Damage, 12)), _reactions.damage)
	assert_eq(_reactions.ReactionFor(_result(CombatResult.Kind.Debuff_Tick, 3)), _reactions.damage)

func test_a_zero_amount_hit_or_heal_has_no_reaction() -> void:
	assert_null(_reactions.ReactionFor(_result(CombatResult.Kind.Damage, 0)))
	assert_null(_reactions.ReactionFor(_result(CombatResult.Kind.Heal, 0)))

func test_heal_and_death_rows() -> void:
	assert_eq(_reactions.ReactionFor(_result(CombatResult.Kind.Heal, 5)), _reactions.heal)
	assert_eq(_reactions.ReactionFor(_result(CombatResult.Kind.Death)), _reactions.death)

func test_other_kinds_have_no_reaction() -> void:
	assert_null(_reactions.ReactionFor(_result(CombatResult.Kind.Turn_Bar_Bump)))
	assert_null(_reactions.ReactionFor(_result(CombatResult.Kind.Status_Applied)),
			"A status landing plays the status's own effect instead")

func test_the_target_hurts_on_a_hit_and_cries_out_on_death() -> void:
	var character: Character = Character.new()
	character._hurt_cue = SoundCue.new()
	character._death_cue = SoundCue.new()
	assert_eq(ResultReactions.VocalCueFor(_result(CombatResult.Kind.Damage, 4), character), character._hurt_cue)
	assert_eq(ResultReactions.VocalCueFor(_result(CombatResult.Kind.Death), character), character._death_cue)
	assert_null(ResultReactions.VocalCueFor(_result(CombatResult.Kind.Damage, 0), character))
	assert_null(ResultReactions.VocalCueFor(_result(CombatResult.Kind.Heal, 4), character))
