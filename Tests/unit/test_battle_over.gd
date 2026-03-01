extends GutTest

# --- 1. MOCK Setup ---

const MainScript = preload("res://Scripts/main.gd")
const BattleOverScreen = preload("uid://b4s2d8usop6na")

# Hand-rolled fake for Main_Instance.
# GUT 9.x cannot double inner classes (the doubler generates an empty 'extends'
# directive for them, causing a parse error). Extending the inner class directly
# in user GDScript works fine and satisfies the 'Main_Instance' type on main._instance.
class FakeMainInstance extends MainScript.Main_Instance:
	var _change_scene_calls: Array = []

	func change_scene(p_context: ContextContainer) -> void:
		_change_scene_calls.append(p_context)

	func Init() -> void:
		pass

# Define a mock for the ContextContainer class.
class MockContextContainer extends ContextContainer:
	pass

# --- 2. Test Scene Setup ---
var _fake_main: FakeMainInstance
var screen: Control
var context: ContextContainer

func before_each():
	print("\nbefore_each")

	# 1. Create the fake and inject it into the main singleton.
	_fake_main = FakeMainInstance.new()
	main._instance = _fake_main

	# 2. Build the minimal scene tree that post_battle_menu.gd expects.
	screen = Control.new()
	screen.name = "BattleOverScreen"

	# _texture_rect_background
	var texture_rect = TextureRect.new()
	texture_rect.name = "TextureRect_Background"
	screen.add_child(texture_rect)

	var margin_container = MarginContainer.new()
	margin_container.name = "MarginContainer"
	screen.add_child(margin_container)

	var vbox_container = VBoxContainer.new()
	vbox_container.name = "VBoxContainer"
	margin_container.add_child(vbox_container)

	# _heading
	var heading_label = Label.new()
	heading_label.name = "Label"
	vbox_container.add_child(heading_label)

	# _h_box_container and first Button
	var h_box_container = HBoxContainer.new()
	h_box_container.name = "HBoxContainer"
	vbox_container.add_child(h_box_container)
	var button = Button.new()
	h_box_container.add_child(button)

	# 3. Assign the script, then add to the GUT tree.
	#    add_child_autofree puts screen in the scene tree (fixing grab_focus) and
	#    auto-frees it after each test (fixing orphans). _ready() fires automatically.
	screen.set_script(BattleOverScreen)
	add_child_autofree(screen)

	# 4. Shared ContextContainer for use across tests.
	context = ContextContainer.new()

	for child in GetAllChildren(screen, ""):
		print(child)

func GetAllChildren(node: Node, indentation: String) -> Array:
	var children = []
	var depth: String = indentation
	depth += "--"
	for child in node.get_children():
		children.append(depth + child.name)
		children += GetAllChildren(child, depth)
	return children

func after_each():
	# screen is freed by add_child_autofree; only free the standalone nodes.
	if is_instance_valid(context):
		context.free()
	if is_instance_valid(_fake_main):
		_fake_main.free()
	# Restore the main singleton so the mock does not leak between tests.
	main._instance = null

# --- 3. Test Cases ---

func test_01_ready_calls_focus_button():
	print(get_stack()[0]["function"])
	# _ready() calls focus_button(); verify the button is focusable.
	var button = screen.get_node("MarginContainer/VBoxContainer/HBoxContainer").get_child(0)
	assert_eq(Control.FocusMode.FOCUS_ALL, button.focus_mode)

func test_02_visibility_changed_calls_focus_button():
	print(get_stack()[0]["function"])
	# Call _on_visibility_changed() directly (the .tscn signal connection is not
	# present in the manually-built scene, and 'await signal' on a node managed
	# by add_child_autofree causes a "locked object" error during cleanup).
	var h_box_container = screen.get_node("MarginContainer/VBoxContainer/HBoxContainer")

	screen.visible = true
	screen.call("_on_visibility_changed")

	var button = h_box_container.get_child(0)
	assert_eq(Control.FocusMode.FOCUS_ALL, button.focus_mode)

func test_03_init_sets_loss_screen():
	print(get_stack()[0]["function"])
	# Init() reads Battle_Result from _context._arguments and sets UI accordingly.
	# Use an empty _player_battle_characters (default) to skip the _character_repr loop.
	context._arguments["Battle_Result"] = "Loss"

	screen.Init(context)

	var background = screen.get_node("TextureRect_Background")
	assert_eq(background.texture.resource_path, "res://Assets/Champ_Collector/UI/Loss_Screen/Loss_1.png")
	assert_eq(background.size.x, 1280.0)
	assert_eq(background.size.y, 720.0)

	var heading = screen.get_node("MarginContainer/VBoxContainer/Label")
	assert_eq(heading.text, "Lost")

func test_07_on_button_edit_team_changes_to_pre_battle_menu():
	print(get_stack()[0]["function"])
	# The handler sets _context._scene then calls main.GetInstance().change_scene().
	# Inject a context so _context is not null.
	screen._context = context

	screen._on_button_edit_team_button_up()

	assert_eq(1, _fake_main._change_scene_calls.size(), "change_scene should be called once")
	var passed_context = _fake_main._change_scene_calls[0]
	# assert_is does not support user-defined GDScript classes; use 'is' directly.
	assert_true(passed_context is ContextContainer, "change_scene arg should be a ContextContainer")
	assert_eq("res://Scenes/ui/Pre_Battle_Menu.tscn", passed_context._scene)
