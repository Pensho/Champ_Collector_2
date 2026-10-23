class_name EffectVariant extends Resource

## A skill's look on a shared effect archetype. Null textures and cues keep the archetype's own.

@export var texture: Texture2D
@export var particle_texture: Texture2D
@export var tint: Color = Color.WHITE
@export var scale: float = 1.0
@export var cast_cue: SoundCue
@export var impact_cue: SoundCue
