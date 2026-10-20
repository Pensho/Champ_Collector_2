class_name SoundCue extends Resource

## Variants and pitch or volume spread come from an AudioStreamRandomizer stream.
@export var stream: AudioStream
@export var bus: StringName = &"Sound Effects"
@export var volume_db: float = 0.0
## Instances of this cue playing at once; a request beyond it is dropped. 0 means unlimited.
@export var maximum_simultaneous: int = 0
## Seconds; a request sooner than this after the cue's previous start is dropped.
@export var minimum_interval: float = 0.0
