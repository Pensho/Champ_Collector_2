class_name PlanTrait extends CharacterTrait

var _trait_texture: Texture2D
var _title: String = "Title"
var _body: String = "Body"

func Init() -> void:
	_trait_texture = load("uid://u2rpxcarwct2")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

func StartOfTurn(p_character_repr: CharacterRepresentation) -> TraitStartTurn:
	return null
