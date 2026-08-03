class_name Skill extends Resource

const Statuses = preload("uid://bp3pvvar4437")

@export var name: String = "New Skill"
@export var description: String = ""
@export var icon_path: String = ""
@export var target: Types.Skill_Target
# cooldown is the amount of turns until the skill can be used again.
@export var cooldown: int = 0

## Ordered, self-resolving effects.
@export var effects: Array[SkillEffect]

var cooldown_left: int = 0
