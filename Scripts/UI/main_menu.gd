extends Control

const GRASSLANDS_DAWN = preload("uid://c5josnkodntag")
const GRASSLANDS_DAY = preload("uid://bj3f2iipfovw8")
const GRASSLANDS_DUSK = preload("uid://ba31cn3hmntgv")
const GRASSLANDS_NIGHT = preload("uid://bsmrvv2vuny5")
const SETTINGS_MENU_SCENE = preload("res://Scenes/ui/Settings_Menu.tscn")

@export var _background: TextureRect

var _settings_menu: SettingsMenu

@onready var _buttons_v_box: VBoxContainer = %ButtonsVBox

func _ready() -> void:
	var date_time: Dictionary = Time.get_datetime_dict_from_system()
	if(date_time["hour"] >= 5 and date_time["hour"] <= 9):
		_background.texture = GRASSLANDS_DAWN
	elif(date_time["hour"] >= 18 and date_time["hour"] <= 21):
		_background.texture = GRASSLANDS_DUSK
	elif(date_time["hour"] >= 22 or date_time["hour"] <= 4):
		_background.texture = GRASSLANDS_NIGHT
	else:
		_background.texture = GRASSLANDS_DAY

	_settings_menu = SETTINGS_MENU_SCENE.instantiate()
	add_child(_settings_menu)
	_settings_menu.position = Vector2i((get_viewport_rect().size * 0.5) - (_settings_menu.GetSize() * 0.5))
	_settings_menu.hide()

	if(OS.get_name() == "Android" or OS.get_name() == "IOS"):
		return
	focus_button()

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(_p_context_container: ContextContainer) -> void:
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

func _on_settings_button_up() -> void:
	_settings_menu.Init()
	_settings_menu.show()
