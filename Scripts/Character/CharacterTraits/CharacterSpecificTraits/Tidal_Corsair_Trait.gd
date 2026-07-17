class_name TidalCorsairTrait extends CharacterTrait

enum Stack_Type
{
	Empty,
	Steel,
	Sea,
}

const MAX_STACKS: int = 3

class StackDescription:
	var _title: String = "Title"
	var _body: String = "Body"

var _sea_stack_texture: Texture2D
var _steel_stack_texture: Texture2D
var _held_stacks: Array[Stack_Type]
var _steel_description: StackDescription
var _sea_description: StackDescription
var _blank_description: StackDescription

func Init() -> void:
	_held_stacks = [Stack_Type.Empty, Stack_Type.Empty, Stack_Type.Empty]
	_sea_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Sea.png")
	_steel_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_steel_description = StackDescription.new()
	_steel_description._title = "Steel Stack"
	_steel_description._body = ""

	_sea_description = StackDescription.new()
	_sea_description._title = "Sea Stack"
	_sea_description._body = ""

	_blank_description = StackDescription.new()
	_blank_description._title = "Empty Stack"
	_blank_description._body = "Use an ability that grants stacks to fill this slot."

func StartOfBattle() -> void:
	_held_stacks = [Stack_Type.Empty, Stack_Type.Empty, Stack_Type.Empty]

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	for i in _held_stacks.size():
		match _held_stacks[i]:
			Stack_Type.Steel:
				p_character_repr.SetTraitElement(_steel_stack_texture, i)
				p_character_repr.SetTraitElementToolTip(_steel_description._title, _steel_description._body, i)
			Stack_Type.Sea:
				p_character_repr.SetTraitElement(_sea_stack_texture, i)
				p_character_repr.SetTraitElementToolTip(_sea_description._title, _sea_description._body, i)
			Stack_Type.Empty:
				p_character_repr.SetBlankTraitElement(i)
				p_character_repr.SetTraitElementToolTip(_blank_description._title, _blank_description._body, i)

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	var skill_result: TraitSkillResult = TraitSkillResult.new()
	match p_skill_name:
		"Boarding Strike":
			for i in _held_stacks.size():
				if (_held_stacks[i] == Stack_Type.Empty):
					_held_stacks[i] = Stack_Type.Steel
					break;
		"Saltwater Shot":
			for i in _held_stacks.size():
				if (_held_stacks[i] == Stack_Type.Empty):
					_held_stacks[i] = Stack_Type.Sea
					break;
		"Corsairs Reckoning":
			for i in _held_stacks.size():
				if (_held_stacks[i] == Stack_Type.Steel):
					skill_result._damage_multiplier += 0.5
				elif (_held_stacks[i] == Stack_Type.Sea):
					skill_result._turn_bar_bump -= 0.1
				_held_stacks[i] = Stack_Type.Empty

	return skill_result
