class_name SkillPresentation extends Resource

## How a skill's effect is shown: an archetype scene with this skill's variant on it. The
## battle view holds the skill's results and releases them on the scene's impact markers.

enum Spawn_Mode {
	Per_Target,
	Per_Target_Staggered,
	Field_Wide,
}

## A SkillEffectScene. A bespoke scene is an archetype with no variant.
@export var archetype: PackedScene
@export var variant: EffectVariant
@export var spawn_mode: Spawn_Mode = Spawn_Mode.Per_Target
## Per_Target_Staggered only: seconds between one target's instance and the next.
@export var stagger_seconds: float = 0.0
## Played when a cascade echoes this skill; null replays the skill's own archetype and variant.
@export var echo_archetype: PackedScene
@export var echo_variant: EffectVariant
