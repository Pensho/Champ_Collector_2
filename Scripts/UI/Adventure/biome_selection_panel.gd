class_name BiomeSelectionPanel extends Control

signal pressed(p_panel: BiomeSelectionPanel)
signal hover_changed(p_panel: BiomeSelectionPanel, p_is_hovered: bool)

const GRAYSCALE_SHADER = preload("res://Assets/Champ_Collector/Shaders/grayscale.gdshader")
const SELECTION_TWEEN_SECONDS: float = 0.2

@export var _texture_button: TextureButton
@export var _label_name: Label

var _panel_material: ShaderMaterial
var _grayscale_tween: Tween
var _grayscale_amount: float = 1.0

func _ready() -> void:
	_panel_material = ShaderMaterial.new()
	_panel_material.shader = GRAYSCALE_SHADER
	_panel_material.set_shader_parameter("grayscale_amount", _grayscale_amount)
	_texture_button.material = _panel_material

func Populate(p_entry: ActBiomeEntry) -> void:
	_texture_button.texture_normal = p_entry.selection_texture
	_label_name.text = p_entry.display_name

func SetSelected(p_is_selected: bool) -> void:
	var target: float = 0.0 if p_is_selected else 1.0
	if _grayscale_tween:
		_grayscale_tween.kill()
	_grayscale_tween = create_tween()
	_grayscale_tween.tween_method(_SetGrayscaleAmount, _grayscale_amount, target, SELECTION_TWEEN_SECONDS)

func _SetGrayscaleAmount(p_amount: float) -> void:
	_grayscale_amount = p_amount
	_panel_material.set_shader_parameter("grayscale_amount", p_amount)

func SetInteractive(p_is_interactive: bool) -> void:
	_texture_button.disabled = not p_is_interactive

func _on_texture_button_mouse_entered() -> void:
	hover_changed.emit(self, true)

func _on_texture_button_mouse_exited() -> void:
	hover_changed.emit(self, false)

func _on_texture_button_button_up() -> void:
	pressed.emit(self)
