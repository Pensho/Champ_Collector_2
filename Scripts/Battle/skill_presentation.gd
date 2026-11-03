class_name SkillPresentation extends Resource

## How a skill's effect is shown: an archetype scene with this skill's variant on it. The
## battle view holds the skill's results and releases them on the scene's impact markers.

enum Spawn_Mode {
	Per_Target,
	Per_Target_Staggered,
	Field_Wide,
	## One instance per top-level effect, aimed at where that effect's first result landed, for a
	## skill whose effects each pick their own target (the Hue-Eater's beams).
	Per_Effect,
}

## A SkillEffectScene. A bespoke scene is an archetype with no variant.
@export var archetype: PackedScene
@export var variant: EffectVariant
@export var spawn_mode: Spawn_Mode = Spawn_Mode.Per_Target
## Per_Target_Staggered and Per_Effect only: seconds between one instance and the next.
@export var stagger_seconds: float = 0.0

## Seconds between one instance and the next; only staggered modes space them out.
func StaggerSeconds() -> float:
	return stagger_seconds if spawn_mode in [Spawn_Mode.Per_Target_Staggered, Spawn_Mode.Per_Effect] else 0.0
