class_name PlanReachOverlay extends TextureRect

const PLAN_TRAIT_TURNBAR_TEXTURE = preload(
	"res://Assets/Champ_Collector/Icons/Abilities/Plan/Plan_Trait_Turnbar_Texture_2.jpg"
)
const PLAN_REACH_SHADER = preload("res://Assets/Champ_Collector/Shaders/plan_reach_overlay.gdshader")

var _owner_icon: TextureRect
var _reach_px: float
var _owner: Character
var _bar_height: float
var _bar_width: float
var _ahead: bool
var _atlas_texture: AtlasTexture

var _texture_width: float
var _texture_height: float

## p_ahead mirrors the overlay to cover the span in front of the owner instead of
## behind it (e.g. Shield Wall's both-directions proximity, alongside a second,
## unmirrored instance covering behind).
func Setup(
		p_owner_icon: TextureRect,
		p_reach_px: float,
		p_tint: Color,
		p_owner: Character,
		p_bar_height: float,
		p_bar_width: float,
		p_ahead: bool = false) -> void:
	_owner_icon = p_owner_icon
	_reach_px = p_reach_px
	_owner = p_owner
	_bar_height = p_bar_height
	_bar_width = p_bar_width
	_ahead = p_ahead

	_texture_width = PLAN_TRAIT_TURNBAR_TEXTURE.get_width()
	_texture_height = PLAN_TRAIT_TURNBAR_TEXTURE.get_height()

	_atlas_texture = AtlasTexture.new()
	_atlas_texture.atlas = PLAN_TRAIT_TURNBAR_TEXTURE
	self.texture = _atlas_texture
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.stretch_mode = TextureRect.STRETCH_KEEP
	self.flip_h = _ahead
	self.z_index = 5

	var shader_material := ShaderMaterial.new()
	shader_material.shader = PLAN_REACH_SHADER
	shader_material.set_shader_parameter("tint", p_tint)
	self.material = shader_material
	show()

func _process(_delta: float) -> void:
	if (_owner._current_health <= 0):
		hide()
		return

	var owner_center: float = _owner_icon.position.x + (_owner_icon.size.x / 2.0)
	var left: float
	var right: float
	if (_ahead):
		left = owner_center
		right = min(_bar_width, left + _reach_px)
	else:
		right = owner_center
		left = max(0.0, right - _reach_px)
	var width: float = right - left
	if (width <= 0.0):
		hide()
		return

	_atlas_texture.region = Rect2(_texture_width - width, 0.0, width, _texture_height)
	size = Vector2(width, _texture_height)
	position = Vector2(left, (_bar_height - _texture_height) / 2.0)
	material.set_shader_parameter("fade_uv", 5.0 / width)
	material.set_shader_parameter("region_uv_range", Vector2((_texture_width - width) / _texture_width, 1.0))
