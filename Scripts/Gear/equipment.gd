class_name Equipment extends Node

var _instance_ID : int = 0
var _held_by: int = -1
var _level: int = 0

# Preset Data
var _name: String = ""
var _texture: String = ""

var _rarity: Types.Rarity
var _slot: Types.Slot
var _item_type: Types.Item_Type = Types.Item_Type.Standard
var _relic_effect: RelicEffect = null

var _preset_path: String = ""

var _attributes: Dictionary[Types.Attribute, int] = {
	Types.Attribute.Health: 0,
	Types.Attribute.Speed: 0,
	Types.Attribute.Attack: 0,
	Types.Attribute.Defence: 0,
	Types.Attribute.Accuracy: 0,
	Types.Attribute.Resistance: 0,
	Types.Attribute.Mysticism: 0,
	Types.Attribute.Knowledge: 0,
	Types.Attribute.CritChance: 0,
	Types.Attribute.CritDamage: 0,
}

func InstantiateNew(preset: EquipmentPreset, instance_ID: int) -> void:
	_instance_ID = instance_ID

	_name = preset._name
	_texture = preset._texture_path
	_rarity = preset._rarity
	_slot = preset._slot
	_item_type = preset._item_type
	_preset_path = preset._preset_path

	if(null != preset._relic_effect):
		_relic_effect = preset._relic_effect.duplicate(true)
		_relic_effect.Init(_rarity)

	_attributes[Types.Attribute.Health] = preset._attributes[Types.Attribute.Health]
	_attributes[Types.Attribute.Speed] = preset._attributes[Types.Attribute.Speed]
	_attributes[Types.Attribute.Attack] = preset._attributes[Types.Attribute.Attack]
	_attributes[Types.Attribute.Defence] = preset._attributes[Types.Attribute.Defence]
	_attributes[Types.Attribute.Accuracy] = preset._attributes[Types.Attribute.Accuracy]
	_attributes[Types.Attribute.Resistance] = preset._attributes[Types.Attribute.Resistance]
	_attributes[Types.Attribute.Mysticism] = preset._attributes[Types.Attribute.Mysticism]
	_attributes[Types.Attribute.Knowledge] = preset._attributes[Types.Attribute.Knowledge]
	_attributes[Types.Attribute.CritChance] = preset._attributes[Types.Attribute.CritChance]
	_attributes[Types.Attribute.CritDamage] = preset._attributes[Types.Attribute.CritDamage]

func CanUpgrade() -> bool:
	return _level < Game_Balance.MAX_ITEM_LEVEL

static func SetupAttributeGain(p_item_type: Types.Item_Type) -> int:
	if(Types.Item_Type.Relic == p_item_type):
		return ceili(Game_Balance.ITEM_ATTRIBUTE_PER_RARITY / 2.0)
	return Game_Balance.ITEM_ATTRIBUTE_PER_RARITY

static func UpgradeAttributeGain(p_rarity: Types.Rarity, p_item_type: Types.Item_Type) -> int:
	var gain: int = Game_Balance.ITEM_UPGRADE_FLAT_BONUS + int(p_rarity)
	if(Types.Item_Type.Relic == p_item_type):
		return ceili(gain / 2.0)
	return gain

func GetUpgradeGain() -> int:
	return Equipment.UpgradeAttributeGain(_rarity, _item_type)

func Upgrade() -> void:
	var candidate_attributes: Array = []
	for attribute in _attributes.keys():
		if(0 < _attributes[attribute]):
			candidate_attributes.append(attribute)
	if(candidate_attributes.is_empty()):
		candidate_attributes = Game_Balance.ITEM_TYPE_ATTRIBUTES[_slot]

	var chosen_attribute = candidate_attributes[randi() % candidate_attributes.size()]
	_attributes[chosen_attribute] += GetUpgradeGain()
	_level += 1
