class_name ResultReaction extends Resource

## How a character reacts when a result of one kind is presented on them. A null archetype
## or cue plays nothing.

@export var flash_color: Color = Color.WHITE
@export var archetype: PackedScene
@export var variant: EffectVariant
@export var cue: SoundCue
