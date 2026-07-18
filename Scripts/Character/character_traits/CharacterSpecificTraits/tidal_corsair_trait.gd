class_name TidalCorsairTrait extends CharacterTrait

enum Stack_Type
{
	Empty,
	Steel,
	Sea,
}

const MAX_STACKS: int = 3

const DAMAGE_PER_STEEL_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.45,
	Types.Rarity.Rare: 0.50,
	Types.Rarity.Epic: 0.55,
	Types.Rarity.Legendary: 0.60,
}

const TURN_BAR_PER_SEA_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.08,
	Types.Rarity.Rare: 0.10,
	Types.Rarity.Epic: 0.12,
	Types.Rarity.Legendary: 0.14,
}

class StackDescription:
	var _title: String = "Title"
	var _body: String = "Body"

var _sea_stack_texture: Texture2D
var _steel_stack_texture: Texture2D
var _held_stacks: Array[Stack_Type]
var _steel_description: StackDescription
var _sea_description: StackDescription
var _blank_description: StackDescription
var _damage_per_steel_stack: float = 0.0
var _turn_bar_per_sea_stack: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_damage_per_steel_stack = DAMAGE_PER_STEEL_STACK.get(p_rarity, 0.0)
	_turn_bar_per_sea_stack = TURN_BAR_PER_SEA_STACK.get(p_rarity, 0.0)
	_held_stacks = [Stack_Type.Empty, Stack_Type.Empty, Stack_Type.Empty]
	_sea_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Sea.png")
	_steel_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_steel_description = StackDescription.new()
	_steel_description._title = "Steel Stack"
	_steel_description._body = ("Consumed by Corsair's Reckoning for +" +
			str(int(round(100.0 * _damage_per_steel_stack))) + "% damage.")

	_sea_description = StackDescription.new()
	_sea_description._title = "Sea Stack"
	_sea_description._body = ("Consumed by Corsair's Reckoning for -" +
			str(int(round(100.0 * _turn_bar_per_sea_stack))) + "% target turn bar.")

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
					skill_result._damage_multiplier += _damage_per_steel_stack
				elif (_held_stacks[i] == Stack_Type.Sea):
					skill_result._turn_bar_bump -= _turn_bar_per_sea_stack
				_held_stacks[i] = Stack_Type.Empty

	return skill_result
