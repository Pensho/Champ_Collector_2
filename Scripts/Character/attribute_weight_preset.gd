class_name AttributeWeightPreset extends Resource

@warning_ignore_start("unused_private_class_variable")

@export var _name: String

@export var _weights: Dictionary[Types.Attribute, int] = {
	Types.Attribute.Health: 0,
	Types.Attribute.Speed: 0,
	Types.Attribute.Attack: 0,
	Types.Attribute.Defence: 0,
	Types.Attribute.Accuracy: 0,
	Types.Attribute.Resistance: 0,
	Types.Attribute.Mysticism: 0,
	Types.Attribute.Knowledge: 0,
}

@export var _description: String = ""

@warning_ignore_restore("unused_private_class_variable")
