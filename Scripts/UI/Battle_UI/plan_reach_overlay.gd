class_name PlanReachOverlay extends TextureRect

const PLAN_TRAIT_TURNBAR_TEXTURE = preload("res://Assets/Champ_Collector/Icons/Abilities/Plan/Plan_Trait_Turnbar_Texture.jpg")
const PLAN_REACH_SHADER = preload("res://Assets/Champ_Collector/Shaders/plan_reach_overlay.gdshader")

var _owner_icon: TextureRect
var _reach_px: float
var _owner: Character
var _bar_height: float
var _atlas_texture: AtlasTexture

var _texture_width: float
var _texture_height: float

func Setup(p_owner_icon: TextureRect, p_reach_px: float, p_tint: Color, p_owner: Character, p_bar_height: float) -> void:
	_owner_icon = p_owner_icon
	_reach_px = p_reach_px
	_owner = p_owner
	_bar_height = p_bar_height
	
	_texture_width = PLAN_TRAIT_TURNBAR_TEXTURE.get_width()
	_texture_height = PLAN_TRAIT_TURNBAR_TEXTURE.get_height()

	_atlas_texture = AtlasTexture.new()
	_atlas_texture.atlas = PLAN_TRAIT_TURNBAR_TEXTURE
	self.texture = _atlas_texture
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.stretch_mode = TextureRect.STRETCH_KEEP
	self.z_index = 5

	var shader_material := ShaderMaterial.new()
	shader_material.shader = PLAN_REACH_SHADER
	shader_material.set_shader_parameter("tint", p_tint)
	self.material = shader_material
	show()

func _process(_delta: float) -> void:
	if (_owner._currentHealth <= 0):
		hide()
		return
	
	var right: float = _owner_icon.position.x
	var left: float = max(0.0, right - _reach_px)
	var width: float = right - left
	if (width <= 0.0):
		hide()
		return

	_atlas_texture.region = Rect2(_texture_width - width, 0.0, width, _texture_height)
	size = Vector2(width, _bar_height)
	position = Vector2(left, 0.0)
	material.set_shader_parameter("fade_uv", 5.0 / width)
	material.set_shader_parameter("region_uv_range", Vector2((_texture_width - width) / _texture_width, 1.0))
