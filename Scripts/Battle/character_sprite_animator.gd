class_name CharacterSpriteAnimator extends Node2D

const SPRITE_SHADER = preload("res://Assets/Champ_Collector/Shaders/character_sprite.gdshader")

const IDLE_SCALE_AMOUNT: float = 0.0
const IDLE_PERIOD_SECONDS: float = 2.4

const IMPACT_SQUASH_SECONDS: float = 0.05
const IMPACT_SETTLE_SECONDS: float = 0.12
const KNOCKBACK_DISTANCE: float = 10.0

const LUNGE_DISTANCE: float = 18.0
const LUNGE_OUT_SECONDS: float = 0.12
const LUNGE_BACK_SECONDS: float = 0.12

const DEATH_SECONDS: float = 0.3

@export var _pivot: Node2D
@export var _sprite: TextureRect

var _sprite_material: ShaderMaterial

var _idle_phase: float = randf() * TAU
var _idle_enabled: bool = true
var _dead: bool = false

var _reaction_offset: Vector2 = Vector2.ZERO
var _reaction_scale: Vector2 = Vector2.ONE
var _reaction_skew: float = 0.0

var _reaction_tween: Tween
var _flash_tween: Tween
var _grayscale_tween: Tween

func _ready() -> void:
	_sprite_material = ShaderMaterial.new()
	_sprite_material.shader = SPRITE_SHADER
	_sprite.material = _sprite_material

func _process(p_delta: float) -> void:
	var idle_scale_y: float = 1.0
	if(_idle_enabled and not _dead):
		_idle_phase = fmod(_idle_phase + p_delta * TAU / IDLE_PERIOD_SECONDS, TAU)
		var wave: float = (sin(_idle_phase) * 0.5) + 0.5
		idle_scale_y = 1.0 + (IDLE_SCALE_AMOUNT * wave)
	_pivot.position = _reaction_offset
	_pivot.skew = _reaction_skew
	_sprite.scale = Vector2(_reaction_scale.x, idle_scale_y * _reaction_scale.y)

func SetIdleEnabled(p_enabled: bool) -> void:
	_idle_enabled = p_enabled

# p_direction: which way to knock the target back, sign only (positive = knocked toward +x).
func PlayImpact(p_intensity: float, p_direction: float) -> void:
	if(_dead):
		return
	var stretch: float = ImpactIntensity.SquashForIntensity(p_intensity)
	if(_reaction_tween):
		_reaction_tween.kill()
	_reaction_tween = create_tween()
	_reaction_tween.set_parallel(true)
	var stretched_scale: Vector2 = Vector2(1.0 - (stretch * 0.5), 1.0 + stretch)
	_reaction_tween.tween_property(self, "_reaction_scale", stretched_scale, IMPACT_SQUASH_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var knockback_offset: Vector2 = Vector2(KNOCKBACK_DISTANCE * p_intensity * signf(p_direction), 0.0)
	_reaction_tween.tween_property(self, "_reaction_offset", knockback_offset, IMPACT_SQUASH_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reaction_tween.chain().tween_property(self, "_reaction_scale", Vector2.ONE, IMPACT_SETTLE_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_reaction_tween.chain().parallel().tween_property(self, "_reaction_offset", Vector2.ZERO, IMPACT_SETTLE_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_PlayFlash(p_intensity)

func PlayLunge(p_direction: float) -> void:
	if(_dead):
		return
	if(_reaction_tween):
		_reaction_tween.kill()
	_reaction_scale = Vector2.ONE
	var offset: Vector2 = Vector2(LUNGE_DISTANCE * signf(p_direction), 0.0)
	_reaction_tween = create_tween()
	_reaction_tween.tween_property(self, "_reaction_offset", offset, LUNGE_OUT_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reaction_tween.tween_property(self, "_reaction_offset", Vector2.ZERO, LUNGE_BACK_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func PlayDeath() -> void:
	if(_dead):
		return
	_dead = true
	if(_reaction_tween):
		_reaction_tween.kill()
	_reaction_scale = Vector2.ONE
	_reaction_offset = Vector2.ZERO
	_reaction_skew = 0.0
	if(_grayscale_tween):
		_grayscale_tween.kill()
	_grayscale_tween = create_tween()
	_grayscale_tween.tween_method(
			func(v: float): _sprite_material.set_shader_parameter("grayscale_amount", v),
			0.0, 1.0, DEATH_SECONDS)

func Revive() -> void:
	_dead = false
	_reaction_offset = Vector2.ZERO
	_reaction_scale = Vector2.ONE
	_reaction_skew = 0.0
	if(_grayscale_tween):
		_grayscale_tween.kill()
	_sprite_material.set_shader_parameter("grayscale_amount", 0.0)

func _PlayFlash(p_intensity: float) -> void:
	if(_flash_tween):
		_flash_tween.kill()
	_sprite_material.set_shader_parameter("flash_amount", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_method(
			func(v: float): _sprite_material.set_shader_parameter("flash_amount", v),
			1.0, 0.0, ImpactIntensity.FlashSecondsForIntensity(p_intensity))
