class_name BattleUI extends Control

@warning_ignore_start("unused_private_class_variable")
@export var _skill_buttons: Array[SkillButton]
@onready var skill_focus: TextureRect = $Skill_Focus
@onready var _turn_bar: TurnBar = $PlayerInfoBox
@warning_ignore_restore("unused_private_class_variable")

@export var _battle_duration_label: Label

const COMBAT_EFFECT_TEXT_TEMPLATE = preload("uid://caq22aj34qk1f")
const SKILL_GLOW_POS_HIDDEN: Vector2 = Vector2(-2000.0, 0.0)
const COMBAT_TEXT_SPAWN_POINT: Vector2 = Vector2(100, 70)
const TEXT_SPAWN_DELAY: float = 0.25
var SKILL_GLOW_POS_1: Vector2
var SKILL_GLOW_POS_2: Vector2
var SKILL_GLOW_POS_3: Vector2

signal battle_skill_selected(p_skill_ID: int)

var _damage_number_2d_pool: Array[CombatEffectText] = []
var _allow_new_effects: bool = true
var _spawn_queue: Array[CombatEffectText]
var _spawn_timer: float = 0.0

var _battle_duration := 0.0
var _skill_textures: Dictionary[String, Texture2D]
var _environment_effects: Array[Node]

func Init(p_environment_effects: Array[PackedScene]) -> void:
	SKILL_GLOW_POS_1 = Vector2(_skill_buttons[0].position.x - 25.0, _skill_buttons[0].position.y - 25.0)
	SKILL_GLOW_POS_2 = Vector2(_skill_buttons[1].position.x - 25.0, _skill_buttons[1].position.y - 25.0)
	SKILL_GLOW_POS_3 = Vector2(_skill_buttons[2].position.x - 25.0, _skill_buttons[2].position.y - 25.0)
	for i in p_environment_effects:
		_environment_effects.append(i.instantiate())

func _process(delta: float) -> void:
	_battle_duration += delta
	var minutes := _battle_duration / 60
	var seconds := fmod(_battle_duration, 60)
	_battle_duration_label.text = "%02d:%02d" % [minutes, seconds]
	
	_spawn_timer -= delta
	if(_spawn_timer <= 0.0 and not _spawn_queue.is_empty()):
		var text = _spawn_queue.pop_front()
		add_child(text, true)
		text.Animate()
		_spawn_timer = TEXT_SPAWN_DELAY

func CleanUp() -> void:
	_allow_new_effects = false
	for i in _damage_number_2d_pool:
		i.animation_player.stop()
	_damage_number_2d_pool.clear()

func LoadSkillTexture(p_texture_path: String) -> void:
	if(_skill_textures.has(p_texture_path)):
		return
	if("" == p_texture_path):
		return
	_skill_textures[p_texture_path] = load(p_texture_path)

func SpawnCombatText(p_value: String, p_position: Vector2, p_color: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	if (_allow_new_effects):
		var text: CombatEffectText = GetDamageNumber()
		text.SetValue(p_value, p_position, 100.0, 10.0, p_color)
		_spawn_queue.append(text)

func GetDamageNumber() -> CombatEffectText:
	if (_allow_new_effects):
		if (_damage_number_2d_pool.size() > 0):
			return _damage_number_2d_pool.pop_front()
		else:
			var new_text: CombatEffectText = COMBAT_EFFECT_TEXT_TEMPLATE.instantiate()
			new_text.tree_exiting.connect(
				func():_damage_number_2d_pool.append(new_text))
			return new_text
	return null

func SetSkill(p_texture_path: String, p_title: String, p_description: String, p_slot: int) -> void:
	if(p_slot < 0 or p_slot >= _skill_buttons.size()):
		print("attempting to set a skill out of bounds: ", p_slot)
		return
	
	_skill_buttons[p_slot].icon = _skill_textures[p_texture_path]
	_skill_buttons[p_slot].SetToolTip(p_title, p_description)

func ActiveSkillGlow(p_skill_ID: int) -> void:
	match p_skill_ID:
		
		0:
			skill_focus.position = SKILL_GLOW_POS_1
		1:
			skill_focus.position = SKILL_GLOW_POS_2
		2:
			skill_focus.position = SKILL_GLOW_POS_3
		_:
			print("Invalid option to show skill glow for.")

func HideSkillUI() -> void:
	for button in _skill_buttons:
		button.hide()
	skill_focus.position = SKILL_GLOW_POS_HIDDEN
	_turn_bar.DisableZones(true)

func _on_skill_1_button_up() -> void:
	skill_focus.position = SKILL_GLOW_POS_1
	battle_skill_selected.emit(0)

func _on_skill_2_button_up() -> void:
	skill_focus.position = SKILL_GLOW_POS_2
	battle_skill_selected.emit(1)

func _on_skill_3_button_up() -> void:
	skill_focus.position = SKILL_GLOW_POS_3
	battle_skill_selected.emit(2)
