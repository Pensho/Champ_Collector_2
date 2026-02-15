class_name TidalCorsairTrait extends CharacterTrait

var _sea_stack_texture: Texture2D
var _steel_stack_texture: Texture2D

const MAX_STACKS: int = 3

enum Stack_Type
{
	Empty,
	Steel,
	Sea,
}

var _held_stacks: Array[Stack_Type] = [Stack_Type.Empty, Stack_Type.Empty, Stack_Type.Empty]

func Init() -> void:
	_sea_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Sea.png")
	_steel_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
	_execution_steps[Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Combat_Event.Skill_Cast] = Callable(self, "UseOfSkill")

func StartOfBattle() -> void:
	# Print graphics
	pass

func UpdateBattleGraphics() -> void:
	pass

func UseOfSkill(type: Stack_Type) -> void:
	match type:
		Stack_Type.Steel:
			for i in _held_stacks.size():
				if (_held_stacks[i] == Stack_Type.Empty):
					_held_stacks[i] = Stack_Type.Steel
					break;
		Stack_Type.Sea:
			for i in _held_stacks.size():
				if (_held_stacks[i] == Stack_Type.Empty):
					_held_stacks[i] = Stack_Type.Sea
					break;
		Stack_Type.Empty:
			for i in _held_stacks.size():
				_held_stacks[i] = Stack_Type.Empty
	
	UpdateBattleGraphics()
