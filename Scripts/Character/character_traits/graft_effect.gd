class_name GraftEffect extends CharacterTrait

var _attribute_percent_delta: Dictionary[Types.Attribute, float] = {}

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Hemoclarity/Hemoclarity.png")
	_attribute_percent_delta = _BonusForRarity(p_rarity).duplicate(true)
	for attribute: Types.Attribute in _Drawback().keys():
		_attribute_percent_delta[attribute] = _attribute_percent_delta.get(attribute, 0.0) + _Drawback()[attribute]


func GetAttributeDelta(p_attribute: Types.Attribute, p_base_value: int) -> int:
	var percent: float = _attribute_percent_delta.get(p_attribute, 0.0)
	if(0.0 == percent):
		return 0
	var delta_sign: float = 1.0 if percent > 0.0 else -1.0
	return int(delta_sign * ceilf(p_base_value * absf(percent)))

func _BonusForRarity(_p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {}

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {}
