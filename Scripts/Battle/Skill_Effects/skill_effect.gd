class_name SkillEffect extends Resource

## Base class for a skill's self-resolving effects. ResolveSkill knows nothing about
## effect kinds: it walks Skill.effects in authored order and calls Resolve(context) on
## each one whose condition is met.

## Skill_Default means "use the skill's own target".
@export var target: Types.Skill_Target = Types.Skill_Target.Skill_Default
@export var condition: Types.Skill_Condition = Types.Skill_Condition.None
@export var condition_test: Types.Condition_Test = Types.Condition_Test.At_Least
@export var condition_threshold: float = 0.0
@export var chance: float = 1.0

func Resolve(_p_context: SkillCastContext) -> void:
	pass
