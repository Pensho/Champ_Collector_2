class_name PresentationArchetypes extends Resource

## The shared effect archetypes a skill or status without its own effect falls back on, one
## slot per category of the archetype library. A null slot is an archetype not built yet.

@export var physical_impact: PackedScene
@export var arcane_impact: PackedScene
@export var heal: PackedScene
@export var barrier: PackedScene
@export var buff: PackedScene
@export var debuff: PackedScene
## Plays a status's icon; the default for every status without its own effect.
@export var status_effect: PackedScene
