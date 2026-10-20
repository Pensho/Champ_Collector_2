class_name UISounds extends Node

const DEFAULT_PROFILE: ButtonSoundProfile = preload("res://Data/Sound_Cues/button_standard.tres")

## Only the buttons listed here make sounds; an entry without a profile uses the default.
@export var buttons: Dictionary[NodePath, ButtonSoundProfile] = {}

func _ready() -> void:
	for path: NodePath in buttons:
		var button: BaseButton = get_node_or_null(path) as BaseButton
		if button == null:
			push_warning("UISounds entry is not a BaseButton: %s" % path)
			continue
		var profile: ButtonSoundProfile = buttons[path] if buttons[path] != null else DEFAULT_PROFILE
		button.mouse_entered.connect(_on_button_hovered.bind(button, profile))
		button.focus_entered.connect(_on_button_focused.bind(button, profile))
		button.pressed.connect(_on_button_pressed.bind(button, profile))

func _on_button_hovered(p_button: BaseButton, p_profile: ButtonSoundProfile) -> void:
	if not p_button.disabled:
		Audio_Handler.Play(p_profile.hover_cue)

func _on_button_focused(p_button: BaseButton, p_profile: ButtonSoundProfile) -> void:
	# A click focuses the button it is over; the hover already played.
	if not p_button.is_hovered():
		_on_button_hovered(p_button, p_profile)

func _on_button_pressed(p_button: BaseButton, p_profile: ButtonSoundProfile) -> void:
	if not p_button.disabled:
		Audio_Handler.Play(p_profile.press_cue)
