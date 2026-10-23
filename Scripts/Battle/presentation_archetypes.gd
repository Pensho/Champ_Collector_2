class_name PresentationArchetypes extends Resource

## The shared effect archetypes a skill without its own presentation falls back on, one
## slot per category of the archetype library. A null slot is an archetype not built yet.

@export var physical_impact: PackedScene
@export var arcane_impact: PackedScene
@export var heal: PackedScene
@export var barrier: PackedScene
@export var buff: PackedScene
@export var debuff: PackedScene
@export var echo_pulse: PackedScene
