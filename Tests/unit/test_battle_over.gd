extends GutTest

# --- 1. MOCK Setup ---
# GUT uses "doubles" (mocks/stubs) for dependencies.

# We must preload the MAIN script to access its nested class (Main_Instance).
const MainScript = preload("res://Scripts/main.gd")
const BattleOverScreen = preload("uid://b4s2d8usop6na")
const CHARACTER_COLLECTION_SCRIPT = preload("res://Scripts/Character/character_collection.gd")

# Declare the mock instance of the nested Main_Instance class.
var MainMock_Instance: Object

# Define a mock for the ContextContainer class.
# Assuming ContextContainer is not nested and available globally/via preload.
class MockContextContainer extends ContextContainer:
	pass

# Define a mock for the Character class.
# Assuming Character is not nested and available globally/via preload.
class MockCharacter extends Character:
	pass

var character_collection_mock: Object
var mock_char_1: MockCharacter
var mock_char_2: MockCharacter
var mock_char_3: MockCharacter
var chars_in_collection: Array

# --- 2. Test Scene Setup ---
var screen: Control
var context: ContextContainer

func before_all():
	# Register the inner class so GUT knows how to double it later.
	register_inner_classes(MainScript)

func before_each():
	print("\nbefore_each")
	
	# 1. Setup the core dependencies
	MainMock_Instance = double(MainScript.Main_Instance).new()
	character_collection_mock = double(CHARACTER_COLLECTION_SCRIPT).new()
	
	# 2. Stub essential functions on the mock Main_Instance
	stub(MainMock_Instance, "change_scene")
	stub(MainMock_Instance, "Init") # Prevent unnecessary real Init calls
	
	# 3. Inject the CharacterCollection mock into the Main_Instance mock
	MainMock_Instance._character_collection = character_collection_mock
	
	# 4. Create the scene structure and assign the script
	screen = Control.new()
	screen.name = "BattleOverScreen"
	
	# Mock the TextureRect (_texture_rect_background)
	var texture_rect = TextureRect.new()
	texture_rect.name = "TextureRect_Background"
	screen.add_child(texture_rect)
	
	var margin_container = MarginContainer.new()
	margin_container.name = "MarginContainer"
	screen.add_child(margin_container)
	
	var vbox_container = VBoxContainer.new()
	vbox_container.name = "VBoxContainer"
	margin_container.add_child(vbox_container)
	
	# Mock the Label (_heading)
	var heading_label = Label.new()
	heading_label.name = "Label"
	vbox_container.add_child(heading_label)

	# Mock the HBoxContainer (_h_box_container) and its child Button
	var h_box_container = HBoxContainer.new()
	h_box_container.name = "HBoxContainer"
	vbox_container.add_child(h_box_container)
	var button = Button.new()
	h_box_container.add_child(button)
	
	# 5. Assign the script and instantiate it
	screen.set_script(BattleOverScreen)
	
	# 6. CRITICAL DEPENDENCY INJECTION: Inject the mock instance
	# This uses the 'main_service' variable defined in battle_over.gd for DI.
	#screen.main_service = MainMock_Instance
	main._instance = MainMock_Instance

	# 7. Add to scene tree so grab_focus() works, then call _ready()
	add_child_autoqfree(screen)
	screen.call("_ready")

	# 8. Setup mock characters and state for tests
	mock_char_1 = MockCharacter.new()
	mock_char_2 = MockCharacter.new()
	mock_char_3 = MockCharacter.new()
	context = ContextContainer.new() # Initialize a real ContextContainer

	for child in GetAllChildren(screen, ""):
		print(child)

func GetAllChildren(node: Node, indentation: String) -> Array:
	var children = []
	var depth: String = indentation
	depth += "--"
	for child in node.get_children():
		children.append(depth + child.name)
		children += GetAllChildren(child, depth)  # Recursively add children
	return children

func after_each():
	# Clean up resources created during setup
	# screen is freed automatically by add_child_autoqfree
	if is_instance_valid(context):
		context.free()
	if is_instance_valid(mock_char_1):
		mock_char_1.free()
	if is_instance_valid(mock_char_2):
		mock_char_2.free()
	if is_instance_valid(mock_char_3):
		mock_char_3.free()
	if is_instance_valid(character_collection_mock):
		character_collection_mock.free()

	chars_in_collection.clear()
	# No need to free MainMock_Instance as it's a double and cleared by GUT

# --- 3. Test Cases ---

func test_01_ready_calls_focus_button():
	print(get_stack()[0]["function"])
	# Check if the button's focus mode is correctly set (as per your original test)
	var button = screen.get_node("MarginContainer/VBoxContainer/HBoxContainer").get_child(0)
	assert_eq(Control.FocusMode.FOCUS_ALL, button.focus_mode)

func test_02_visibility_changed_calls_focus_button():
	print(get_stack()[0]["function"])
	# Ensure focus_button() is called when the control becomes visible
	var h_box_container = screen.get_node("MarginContainer/VBoxContainer/HBoxContainer")

	screen.visible = false
	screen.call_deferred("emit_signal", "visibility_changed")
	
	# Using 'await' for cleaner signal waiting
	await screen.visibility_changed

	screen.visible = true
	screen.emit_signal("visibility_changed")
	
	# Check if the button's focus mode is correctly set (as per your original test)
	var button = h_box_container.get_child(0)
	assert_eq(Control.FocusMode.FOCUS_ALL, button.focus_mode)

func test_03_init_sets_loss_screen():
	print(get_stack()[0]["function"])

	# Setup character result UI doubles (Init always runs the character loop)
	var repr_script = preload("res://Scripts/UI/Post_Battle_UI/character_damage_result.gd")
	var repr1 = double(repr_script).new()
	var repr2 = double(repr_script).new()
	var repr3 = double(repr_script).new()
	for r in [repr1, repr2, repr3]:
		stub(r, "SetName")
		stub(r, "SetTexture")
		stub(r, "SetDamageDealt")
	var typed_result_ui: Array[CharacterDamageResultUI] = []
	typed_result_ui.assign([repr1, repr2, repr3])
	screen._character_result_UI = typed_result_ui

	# Stub GetCharacterTexture (called during character loop)
	stub(character_collection_mock, "GetCharacterTexture").to_return(null)

	# Setup mock context with Loss result and 3 characters
	var mock_context = MockContextContainer.new()
	mock_context._arguments["Battle_Result"] = "Loss"
	mock_context._arguments["character_dmg_0"] = 100
	mock_context._arguments["character_dmg_1"] = 200
	mock_context._arguments["character_dmg_2"] = 150
	var typed_chars: Array[Character] = []
	typed_chars.assign([mock_char_1, mock_char_2, mock_char_3])
	mock_context._player_battle_characters = typed_chars

	screen.Init(mock_context)

	# Check Loss-specific UI changes
	var background = screen.get_node("TextureRect_Background")
	assert_eq(background.size.x, 1280.0)
	assert_eq(background.size.y, 720.0)

	var heading = screen.get_node("MarginContainer/VBoxContainer/Label")
	assert_eq(heading.text, "Lost")

#func test_04_init_handles_less_than_3_characters():
	#print(get_stack()[0]["function"])
	#var mock_context = MockContextContainer.new()
	#mock_context._arguments["Battle_Result"] = "Victory"
	#
	#chars_in_collection = [mock_char_1, mock_char_2]
	#
	## Setup the character collection mock behavior
	#stub(character_collection_mock, "GetAllCharacters").to_return(chars_in_collection)
	#stub(character_collection_mock, "Size").to_return(chars_in_collection.size())
	#stub(character_collection_mock, "GetCharacter").to_return(mock_char_1).when_passed(0)
	#stub(character_collection_mock, "GetCharacter").to_return(mock_char_2).when_passed(1)
	#
	#screen.Init(mock_context)
	#
	## Check character collection (should take all 2)
	#assert_eq(screen._context._player_battle_characters.size(), 2)
	#assert_eq(screen._context._player_battle_characters[0], mock_char_1)
	#assert_eq(screen._context._player_battle_characters[1], mock_char_2)

func test_07_on_button_edit_team_changes_to_pre_battle_menu():
	print(get_stack()[0]["function"])
	screen._on_button_edit_team_button_up()
	
	assert_call_count(MainMock_Instance, "change_scene", 1)
	var parameters = get_call_parameters(MainMock_Instance, "change_scene")
	
	# Check the context object passed to change_scene
	assert_is(parameters[0], ContextContainer)
	assert_eq("res://Scenes/ui/Pre_Battle_Menu.tscn", parameters[0]._scene)

func test_08_on_button_end_changes_scene():
	print(get_stack()[0]["function"])
	screen._on_button_end_button_up()
	assert_call_count(MainMock_Instance, "change_scene", 1)
	var params = get_call_parameters(MainMock_Instance, "change_scene")
	assert_is(params[0], ContextContainer)

func test_09_on_button_replay_changes_scene():
	print(get_stack()[0]["function"])
	screen._on_button_replay_button_up()
	assert_call_count(MainMock_Instance, "change_scene", 1)
	var params = get_call_parameters(MainMock_Instance, "change_scene")
	assert_is(params[0], ContextContainer)

func test_10_init_populates_character_result_UI_calls():
	print(get_stack()[0]["function"])
	var repr_script = preload("res://Scripts/UI/Post_Battle_UI/character_damage_result.gd")
	var repr1 = double(repr_script).new()
	var repr2 = double(repr_script).new()
	var repr3 = double(repr_script).new()

	# Stub the methods we expect Init to call
	for r in [repr1, repr2, repr3]:
		stub(r, "SetName")
		stub(r, "SetTexture")
		stub(r, "SetDamageDealt")

	# Inject the repr doubles directly
	var typed_result_ui: Array[CharacterDamageResultUI] = []
	typed_result_ui.assign([repr1, repr2, repr3])
	screen._character_result_UI = typed_result_ui

	# Stub GetCharacterTexture (called during character loop)
	stub(character_collection_mock, "GetCharacterTexture").to_return(null)

	# Setup progress mock for the Victory branch (calls MarkDifficultyCompleted)
	var progress_mock = double(preload("res://Scripts/Worldview/progress_handler.gd")).new()
	stub(progress_mock, "MarkDifficultyCompleted")
	MainMock_Instance._progress = progress_mock

	# Setup mock context with 3 characters and damage values
	var mock_context = MockContextContainer.new()
	mock_context._arguments["Battle_Result"] = "Victory"
	mock_context._arguments["Difficulty"] = 1
	mock_context._arguments["character_dmg_0"] = 100
	mock_context._arguments["character_dmg_1"] = 200
	mock_context._arguments["character_dmg_2"] = 150
	var typed_chars: Array[Character] = []
	typed_chars.assign([mock_char_1, mock_char_2, mock_char_3])
	mock_context._player_battle_characters = typed_chars
	mock_context._static_context = Static_Context.new()

	screen.Init(mock_context)

	# Verify Init populated the UI by calling expected methods
	for r in [repr1, repr2, repr3]:
		assert_call_count(r, "SetName", 1)
		assert_call_count(r, "SetTexture", 1)
		assert_call_count(r, "SetDamageDealt", 1)

	# Verify progress was marked
	assert_call_count(progress_mock, "MarkDifficultyCompleted", 1)
