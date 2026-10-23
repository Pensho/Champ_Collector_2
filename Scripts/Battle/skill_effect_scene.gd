class_name SkillEffectScene extends Node2D

## Root of every effect archetype. The AnimationPlayer holds one animation whose method
## tracks call Impact, CasterLunge and the sound methods below; the battle view releases
## held results on impact_reached. Authored facing right. Pooled instances are reused, so
## Play restores the archetype's own look wherever the variant leaves a field null.

signal impact_reached(p_index: int)
signal lunge_requested
signal finished

enum Anchor {
	Caster,
	Caster_Feet,
	Target,
	Target_Feet,
	Field_Center,
}

const IMPACT_METHOD: StringName = &"Impact"
const RESET_ANIMATION: StringName = &"RESET"

@export var animation_player: AnimationPlayer
@export var anchor: Anchor = Anchor.Target
## Rotates the scene toward the target; otherwise it is mirrored to face away from the caster.
@export var aim_at_target: bool = false
## Receive the variant's texture and tint.
@export var variant_sprites: Array[Sprite2D] = []
## Receive the variant's particle texture and tint.
@export var variant_particles: Array[CPUParticles2D] = []

var _variant: EffectVariant = null
var _loop_handles: Dictionary[StringName, int] = {}
var _sprite_textures: Array[Texture2D] = []
var _particle_textures: Array[Texture2D] = []


func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	for sprite: Sprite2D in variant_sprites:
		_sprite_textures.append(sprite.texture)
	for particles: CPUParticles2D in variant_particles:
		_particle_textures.append(particles.texture)


## p_origin is the anchor point the battle view resolved for this scene's anchor.
func Play(
		p_origin: Vector2,
		p_caster_position: Vector2,
		p_target_position: Vector2,
		p_variant: EffectVariant = null,
		p_scale: float = 1.0) -> void:
	_variant = p_variant
	_ApplyVariant()
	global_position = p_origin
	var size: float = p_scale * (_variant.scale if null != _variant else 1.0)
	rotation = 0.0
	scale = Vector2(size, size)
	if(aim_at_target):
		if(not p_target_position.is_equal_approx(p_origin)):
			rotation = (p_target_position - p_origin).angle()
	elif(p_caster_position.x > p_target_position.x):
		scale.x = -size
	show()
	animation_player.play(_AnimationName())


## Ends the animation early (the battle's presentation deadline) and stops its loops.
func Stop() -> void:
	animation_player.stop()
	_StopAllLoops()
	hide()


func ImpactCount() -> int:
	var animation: Animation = animation_player.get_animation(_AnimationName())
	var count: int = 0
	for track_index in animation.get_track_count():
		if(Animation.TYPE_METHOD != animation.track_get_type(track_index)):
			continue
		for key_index in animation.track_get_key_count(track_index):
			if(IMPACT_METHOD == animation.method_track_get_name(track_index, key_index)):
				count += 1
	return count


func Length() -> float:
	return animation_player.get_animation(_AnimationName()).length


func Impact(p_index: int) -> void:
	impact_reached.emit(p_index)


func CasterLunge() -> void:
	lunge_requested.emit()


func PlayCastSound() -> void:
	if(null != _variant and null != _variant.cast_cue):
		Audio_Handler.Play(_variant.cast_cue)


func PlayImpactSound() -> void:
	if(null != _variant and null != _variant.impact_cue):
		Audio_Handler.Play(_variant.impact_cue)


func PlaySound(p_cue: SoundCue) -> void:
	Audio_Handler.Play(p_cue)


func StartLoop(p_cue: SoundCue, p_key: StringName) -> void:
	StopLoop(p_key)
	_loop_handles[p_key] = Audio_Handler.PlayLoop(p_cue)


func StopLoop(p_key: StringName) -> void:
	if(_loop_handles.has(p_key)):
		Audio_Handler.StopLoop(_loop_handles[p_key])
		_loop_handles.erase(p_key)


func _ApplyVariant() -> void:
	var tint: Color = _variant.tint if null != _variant else Color.WHITE
	for index in variant_sprites.size():
		var texture: Texture2D = _variant.texture if null != _variant else null
		variant_sprites[index].texture = texture if null != texture else _sprite_textures[index]
		variant_sprites[index].self_modulate = tint
	for index in variant_particles.size():
		var particle_texture: Texture2D = _variant.particle_texture if null != _variant else null
		variant_particles[index].texture = (
				particle_texture if null != particle_texture else _particle_textures[index])
		variant_particles[index].self_modulate = tint


func _AnimationName() -> StringName:
	for animation_name: StringName in animation_player.get_animation_list():
		if(RESET_ANIMATION != animation_name):
			return animation_name
	return &""


func _StopAllLoops() -> void:
	for key: StringName in _loop_handles.keys():
		StopLoop(key)


func _on_animation_finished(_p_animation_name: StringName) -> void:
	_StopAllLoops()
	hide()
	finished.emit()
