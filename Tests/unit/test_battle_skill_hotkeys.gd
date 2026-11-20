extends GutTest

const BATTLE_UI_SCENE: PackedScene = preload("res://Scenes/ui/Battle_UI/battle_ui.tscn")

var _battle_ui: BattleUI

func before_each() -> void:
	_battle_ui = BATTLE_UI_SCENE.instantiate()
	add_child_autofree(_battle_ui)
	_battle_ui.Init()
	_battle_ui.ShowSkillButtons()

func _KeyEvent(p_physical_keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = p_physical_keycode
	event.pressed = true
	return event

func test_number_keys_map_to_skill_slots() -> void:
	assert_eq(BattleUI.SkillHotkeySlot(_KeyEvent(KEY_1)), 0)
	assert_eq(BattleUI.SkillHotkeySlot(_KeyEvent(KEY_2)), 1)
	assert_eq(BattleUI.SkillHotkeySlot(_KeyEvent(KEY_3)), 2)
	assert_eq(BattleUI.SkillHotkeySlot(_KeyEvent(KEY_KP_2)), 1)

func test_other_keys_map_to_no_slot() -> void:
	assert_eq(BattleUI.SkillHotkeySlot(_KeyEvent(KEY_4)), -1)

func test_hotkey_selects_a_shown_ready_skill() -> void:
	watch_signals(_battle_ui)

	_battle_ui._unhandled_key_input(_KeyEvent(KEY_2))

	assert_signal_emitted_with_parameters(_battle_ui, "battle_skill_selected", [1])

func test_hotkey_skips_a_skill_on_cooldown() -> void:
	_battle_ui._skill_buttons[0].SetCooldown(2)

	assert_false(_battle_ui.CanUseSkillHotkey(0))
	assert_true(_battle_ui.CanUseSkillHotkey(1))

func test_hotkey_skips_hidden_skills() -> void:
	_battle_ui.HideSkillButtons()

	assert_false(_battle_ui.CanUseSkillHotkey(0))

func test_hotkey_is_blocked_while_the_battle_menu_is_open() -> void:
	_battle_ui._battle_menu.Open()

	assert_false(_battle_ui.CanUseSkillHotkey(0))

func test_hotkey_is_blocked_while_a_confirm_window_is_open() -> void:
	_battle_ui.ShowReagentConfirm(0, "Reagent", "Description")

	assert_false(_battle_ui.CanUseSkillHotkey(0))
