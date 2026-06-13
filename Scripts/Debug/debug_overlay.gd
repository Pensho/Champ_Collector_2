class_name DebugOverlay extends CanvasLayer

## Key that toggles the debug overlay. Editor-only (see _unhandled_key_input).
const TOGGLE_KEY: Key = KEY_F2

## Ordered list of debug pages shown as tabs. Add a new debug capability by
## creating a page scene/script and adding it here - no other part of the
## overlay needs to change.
const PAGE_SCENES: Array[PackedScene] = [
	preload("res://Scenes/debug/pages/Currencies_Progression_Page.tscn"),
	preload("res://Scenes/debug/pages/In_Battle_Page.tscn"),
	preload("res://Scenes/debug/pages/Item_Construction_Page.tscn"),
	preload("res://Scenes/debug/pages/Battle_Launcher_Page.tscn"),
	preload("res://Scenes/debug/pages/Champions_Page.tscn"),
]

@export var _tab_container: TabContainer
@export var _current_scene_label: Label

var _pages: Array[DebugPage] = []

func _ready() -> void:
	hide()
	for page_scene in PAGE_SCENES:
		var page: DebugPage = page_scene.instantiate()
		_tab_container.add_child(page)
		_tab_container.set_tab_title(_tab_container.get_tab_count() - 1, page.page_title)
		_pages.append(page)

func _unhandled_key_input(p_event: InputEvent) -> void:
	if(not OS.has_feature("editor")):
		return
	if(p_event is InputEventKey and p_event.pressed and not p_event.echo and p_event.keycode == TOGGLE_KEY):
		visible = !visible
		if(visible):
			RefreshPages()

func RefreshPages() -> void:
	_current_scene_label.text = "Current scene: " + main.GetInstance()._current_scene.name
	for page in _pages:
		page.Refresh()

func _on_print_scene_tree_button_up() -> void:
	print(get_tree().get_root().get_tree_string_pretty())
