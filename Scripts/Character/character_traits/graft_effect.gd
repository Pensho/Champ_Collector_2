class_name GraftEffect extends CharacterTrait

var _attribute_delta: Dictionary[Types.Attribute, int] = {}

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Hemoclarity/Hemoclarity.png")
	_attribute_delta = _BonusForRarity(p_rarity).duplicate(true)
	for attribute: Types.Attribute in _Drawback().keys():
		_attribute_delta[attribute] = _attribute_delta.get(attribute, 0) + _Drawback()[attribute]

func GetAttributeDelta(p_attribute: Types.Attribute) -> int:
	return _attribute_delta.get(p_attribute, 0)

## Subclasses override to return their attribute bonus scaled for the given rarity.
func _BonusForRarity(_p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, int]:
	return {}

## Subclasses override to return their flat (rarity-independent) drawback.
func _Drawback() -> Dictionary[Types.Attribute, int]:
	return {}
