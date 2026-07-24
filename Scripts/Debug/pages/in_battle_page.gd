extends DebugPage

const TURN_BUMP_RANGE: float = 1.0
const TURN_BUMP_STEP: float = 0.05
const DEFAULT_STATUS_DURATION: int = 2

@export var _not_in_battle_label: Label
@export var _character_rows: VBoxContainer
@export var _status_effect_section: VBoxContainer
@export var _character_option: OptionButton
@export var _buff_option: OptionButton
@export var _debuff_option: OptionButton
@export var _status_duration_spin: SpinBox

var _hp_spins: Dictionary[int, SpinBox] = {}

func _ready() -> void:
	page_title = "In Battle"
	for buff_name in Types.Buff_Type.keys():
		if(Types.Buff_Type.Invalid != Types.Buff_Type[buff_name]):
			_buff_option.add_item(buff_name, Types.Buff_Type[buff_name])
	for debuff_name in Types.Debuff_Type.keys():
		if(Types.Debuff_Type.Invalid != Types.Debuff_Type[debuff_name]):
			_debuff_option.add_item(debuff_name, Types.Debuff_Type[debuff_name])
	_status_duration_spin.min_value = 1
	_status_duration_spin.value = DEFAULT_STATUS_DURATION

func Refresh() -> void:
	var battle: Battle = GetBattle()
	var in_battle: bool = (null != battle and battle._initialized)
	_not_in_battle_label.visible = not in_battle
	_character_rows.visible = in_battle
	_status_effect_section.visible = in_battle
	if(in_battle):
		PopulateCharacterRows(battle)
		PopulateCharacterOption(battle)

func GetBattle() -> Battle:
	var current_scene: Node = main.GetInstance()._current_scene
	if(current_scene is Battle):
		return current_scene as Battle
	return null

func PopulateCharacterRows(p_battle: Battle) -> void:
	for child in _character_rows.get_children():
		child.queue_free()
	_hp_spins.clear()

	for character_id in p_battle._characters.keys():
		var character: Character = p_battle._characters[character_id]
		var max_health: int = character.GetTotalAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 25)

		var label: Label = Label.new()
		label.text = character._name + " (ID " + str(character_id) + ")"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var hp_spin: SpinBox = SpinBox.new()
		hp_spin.min_value = 0
		hp_spin.max_value = max_health
		hp_spin.value = character._current_health
		row.add_child(hp_spin)
		_hp_spins[character_id] = hp_spin

		var set_hp_button: Button = Button.new()
		set_hp_button.text = "Set HP"
		set_hp_button.pressed.connect(_on_set_hp_pressed.bind(character_id))
		row.add_child(set_hp_button)

		var kill_button: Button = Button.new()
		kill_button.text = "Kill"
		kill_button.pressed.connect(_on_kill_pressed.bind(character_id))
		row.add_child(kill_button)

		var revive_button: Button = Button.new()
		revive_button.text = "Revive"
		revive_button.pressed.connect(_on_revive_pressed.bind(character_id))
		row.add_child(revive_button)

		var bump_spin: SpinBox = SpinBox.new()
		bump_spin.min_value = -TURN_BUMP_RANGE
		bump_spin.max_value = TURN_BUMP_RANGE
		bump_spin.step = TURN_BUMP_STEP
		bump_spin.value = TURN_BUMP_STEP
		row.add_child(bump_spin)

		var bump_button: Button = Button.new()
		bump_button.text = "Bump Turn"
		bump_button.pressed.connect(_on_bump_turn_pressed.bind(character_id, bump_spin))
		row.add_child(bump_button)

		_character_rows.add_child(row)

func PopulateCharacterOption(p_battle: Battle) -> void:
	var previously_selected: int = _character_option.get_selected_id()
	_character_option.clear()
	for character_id in p_battle._characters.keys():
		_character_option.add_item(p_battle._characters[character_id]._name + " (ID " + str(character_id) + ")", character_id)
	for i in _character_option.item_count:
		if(_character_option.get_item_id(i) == previously_selected):
			_character_option.select(i)
			break

func _on_set_hp_pressed(p_character_id: int) -> void:
	var battle: Battle = GetBattle()
	if(null == battle or not battle._characters.has(p_character_id)):
		return
	battle._resolver.SetCurrentHealth(p_character_id, int(_hp_spins[p_character_id].value))
	battle.CheckAndHandleBattleOver()

func _on_kill_pressed(p_character_id: int) -> void:
	var battle: Battle = GetBattle()
	if(null == battle or not battle._characters.has(p_character_id)):
		return
	battle._resolver.SetCurrentHealth(p_character_id, 0)
	_hp_spins[p_character_id].value = 0
	battle.CheckAndHandleBattleOver()

func _on_revive_pressed(p_character_id: int) -> void:
	var battle: Battle = GetBattle()
	if(null == battle or not battle._characters.has(p_character_id)):
		return
	var character: Character = battle._characters[p_character_id]
	var max_health: int = character.GetTotalAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	battle._resolver.SetCurrentHealth(p_character_id, max_health)
	battle._character_representations[p_character_id]._character_texture.material = null
	battle._battle_ui._turn_bar._character_turn_markers[p_character_id].material = null
	_hp_spins[p_character_id].value = max_health

func _on_bump_turn_pressed(p_character_id: int, p_bump_spin: SpinBox) -> void:
	var battle: Battle = GetBattle()
	if(null == battle or not battle._characters.has(p_character_id)):
		return
	battle._battle_ui._turn_bar.BumpCharacter(p_character_id, p_bump_spin.value)

func _on_add_buff_button_up() -> void:
	var battle: Battle = GetBattle()
	if(null == battle):
		return
	var character_id: int = _character_option.get_selected_id()
	if(not battle._characters.has(character_id)):
		return
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = _buff_option.get_selected_id() as Types.Buff_Type
	buff.duration = int(_status_duration_spin.value)
	battle._resolver.ApplyBuff(character_id, buff)

func _on_add_debuff_button_up() -> void:
	var battle: Battle = GetBattle()
	if(null == battle):
		return
	var character_id: int = _character_option.get_selected_id()
	if(not battle._characters.has(character_id)):
		return
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = _debuff_option.get_selected_id() as Types.Debuff_Type
	debuff.duration = int(_status_duration_spin.value)
	battle._resolver.ApplyDebuff(character_id, debuff)
