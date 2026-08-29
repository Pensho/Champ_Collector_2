class_name SkillListRow extends ToolTip

@onready var _icon: TextureRect = $MarginContainer/HBoxContainer/TextureRect
@onready var _name_label: Label = $MarginContainer/HBoxContainer/Label_Name
@onready var _cooldown_label: Label = $MarginContainer/HBoxContainer/Label_Cooldown

func SetSkill(p_skill: Skill) -> void:
	if("" != p_skill.icon_path):
		_icon.texture = load(p_skill.icon_path)
	_name_label.text = p_skill.name
	_cooldown_label.text = CooldownText(p_skill.cooldown)
	title_text = p_skill.name
	description_text = p_skill.description

func SetPassive(p_trait: CharacterTrait, p_label: String) -> void:
	_icon.texture = p_trait._trait_texture
	_name_label.text = p_label
	_cooldown_label.text = ""
	title_text = p_trait._title
	description_text = p_trait._body

static func CooldownText(p_cooldown: int) -> String:
	return "" if 0 == p_cooldown else "CD " + str(p_cooldown)

static func PassiveLabel(p_character: Character) -> String:
	if(Types.Role.Symbiote == p_character._role):
		return "Ungrafted" if null == p_character._graft else p_character._trait._title
	return p_character._trait._title
