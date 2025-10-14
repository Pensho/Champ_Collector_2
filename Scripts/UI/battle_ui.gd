class_name BattleUI extends Control

@warning_ignore_start("unused_private_class_variable")
@export var _char_turns: Array[TextureRect]
@onready var _skill_button_1: Button = $Camera2D/Skill_1
@onready var _skill_button_2: Button = $Camera2D/Skill_2
@onready var _skill_button_3: Button = $Camera2D/Skill_3
@export var _character_repr: Array[CharacterRepresentation]
@onready var skill_focus: TextureRect = $Camera2D/Skill_Focus
@warning_ignore_restore("unused_private_class_variable")

const DAMAGE_NUMBER_TEMPLATE = preload("res://Scenes/ui/Damage_Number.tscn")
const SKILL_GLOW_POS_1: Vector2 = Vector2(184.0, 161.0)
const SKILL_GLOW_POS_2: Vector2 = Vector2(398.0, 128.0)
const SKILL_GLOW_POS_3: Vector2 = Vector2(422.0, -66.0)
const SKILL_GLOW_POS_HIDDEN: Vector2 = Vector2(2000.0, 0.0)

signal battle_skill_selected(p_skill_ID: int)

var _damage_number_2d_pool: Array[DamageNumber2D] = []
var _allow_new_effects: bool = true

func CleanUp() -> void:
	_allow_new_effects = false
	for i in _damage_number_2d_pool:
		i.animation_player.stop()
	_damage_number_2d_pool.clear()

func SpawnDamageNumber(p_value: int, p_position: Vector2) -> void:
	if (_allow_new_effects):
		var damage_number: DamageNumber2D = GetDamageNumber()
		add_child(damage_number, true)
		damage_number.SetValueAndAnimate(str(p_value), p_position, 100.0, 10.0)

func GetDamageNumber() -> DamageNumber2D:
	if (_allow_new_effects):
		if (_damage_number_2d_pool.size() > 0):
			return _damage_number_2d_pool.pop_front()
		else:
			var new_damage_number: DamageNumber2D = DAMAGE_NUMBER_TEMPLATE.instantiate()
			new_damage_number.tree_exiting.connect(
				func():_damage_number_2d_pool.append(new_damage_number))
			return new_damage_number
	return null

func SetSkill1Texture(p_texture_path: String) -> void:
	_skill_button_1.icon = load(p_texture_path)

func SetSkill2Texture(p_texture_path: String) -> void:
	_skill_button_2.icon = load(p_texture_path)

func SetSkill3Texture(p_texture_path: String) -> void:
	_skill_button_3.icon = load(p_texture_path)

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

func HideSkillGlow() -> void:
	skill_focus.position = SKILL_GLOW_POS_HIDDEN
	pass

func _on_skill_1_button_up() -> void:
	skill_focus.position = SKILL_GLOW_POS_1
	battle_skill_selected.emit(0)

func _on_skill_2_button_up() -> void:
	skill_focus.position = SKILL_GLOW_POS_2
	battle_skill_selected.emit(1)

func _on_skill_3_button_up() -> void:
	skill_focus.position = SKILL_GLOW_POS_3
	battle_skill_selected.emit(2)
