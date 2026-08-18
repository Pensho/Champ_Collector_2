class_name TraitSkillResult extends RefCounted

var _damage_multiplier: float = 1.0
var _turn_bar_bump: float = 0.0
# Rider data for a buff or debuff this cast is about to apply, keyed by mechanic identity
# (same convention as StatusEffects.Effect.trait_riders) - e.g. Comorbidity's
# &"repeats_per_distinct_debuff", or Brace for Impact's &"attacker_debuff_on_damage".
var _trait_riders: Dictionary[StringName, Variant] = {}
