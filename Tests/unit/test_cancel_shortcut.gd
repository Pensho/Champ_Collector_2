extends GutTest

const OPTIONS_WINDOW_SCENE: PackedScene = preload("res://Scenes/ui/General_UI/Button_With_Options.tscn")
const BATTLE_MENU_SCENE: PackedScene = preload("res://Scenes/ui/Battle_UI/Battle_Menu.tscn")

func _PressEscape() -> void:
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	get_viewport().push_input(escape)

func test_escape_closes_an_options_window() -> void:
	var window: ButtonWithOptions = OPTIONS_WINDOW_SCENE.instantiate()
	add_child_autofree(window)

	_PressEscape()

	assert_false(window.visible)

func test_escape_closes_only_the_top_window() -> void:
	var lower: ButtonWithOptions = OPTIONS_WINDOW_SCENE.instantiate()
	add_child_autofree(lower)
	var upper: ButtonWithOptions = OPTIONS_WINDOW_SCENE.instantiate()
	add_child_autofree(upper)

	_PressEscape()

	assert_false(upper.visible)
	assert_true(lower.visible)

func test_escape_closes_the_battle_menu() -> void:
	var menu: BattleMenu = BATTLE_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	menu.Open()

	_PressEscape()

	assert_false(menu.visible)
