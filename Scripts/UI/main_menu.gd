extends Control

const GRASSLANDS_DAWN = preload("uid://c5josnkodntag")
const GRASSLANDS_DAY = preload("uid://bj3f2iipfovw8")
const GRASSLANDS_DUSK = preload("uid://ba31cn3hmntgv")
const GRASSLANDS_NIGHT = preload("uid://bsmrvv2vuny5")

@onready var _buttons_v_box: VBoxContainer = %ButtonsVBox

@export var _background: TextureRect

func _ready() -> void:
	var dateTime: Dictionary = Time.get_datetime_dict_from_system()
	if(dateTime["hour"] >= 5 and dateTime["hour"] <= 9):
		_background.texture = GRASSLANDS_DAWN
	elif(dateTime["hour"] >= 18 and dateTime["hour"] <= 21):
		_background.texture = GRASSLANDS_DUSK
	elif(dateTime["hour"] >= 22 or dateTime["hour"] <= 4):
		_background.texture = GRASSLANDS_NIGHT
	else:
		_background.texture = GRASSLANDS_DAY
	if(OS.get_name() == "Android" or OS.get_name() == "IOS"):
		return
	focus_button()

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	pass

func _on_start_game_button_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()

func focus_button() -> void:
	if _buttons_v_box:
		var button: Button = _buttons_v_box.get_child(0)
		button.grab_focus()

func _on_save_load_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://caviahtf8gtm4"
	main.GetInstance().change_scene(context_container)
