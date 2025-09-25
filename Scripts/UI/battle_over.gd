extends Control

@onready var _h_box_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer
@onready var _heading: Label = $MarginContainer/VBoxContainer/Label
@onready var _texture_rect_background: TextureRect = $TextureRect_Background

func _ready() -> void:
	focus_button()

func Init(p_context_container: ContextContainer) -> void:
	if(p_context_container._util_text == "Loss"):
		_texture_rect_background.texture = load("res://Assets/Champ Collector/UI/Loss_Screen/Loss_1.png")
		_texture_rect_background.size.x = 1280
		_texture_rect_background.size.y = 720
		_heading.text = "Lost"
	elif(p_context_container._util_text == "Victory"):
		pass

func focus_button() -> void:
	if _h_box_container:
		var button: Button = _h_box_container.get_child(0)
		button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()
