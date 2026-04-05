class_name Character extends Node

func InstantiateNew(p_preset: CharacterPreset, p_instanceID: int) -> void:
	_instanceID = p_instanceID
	_preset_UID = p_preset._preset_UID
	
	_name = p_preset._name
	_texture = p_preset._texture
	_normal_map = p_preset._normal_map
	_rarity = p_preset._rarity
	_faction = p_preset._faction
	_role = p_preset._role
	_skills = p_preset._skills
	if(!p_preset._attribute_weight_types_available.is_empty()):
		_attributes_weights = p_preset._attribute_weight_types_available[randi_range(0, p_preset._attribute_weight_types_available.size() - 1)].duplicate(true)
	
	_attributes[Types.Attribute.Health] = p_preset._health
	_attributes[Types.Attribute.Speed] = p_preset._speed
	_attributes[Types.Attribute.Attack] = p_preset._attack
	_attributes[Types.Attribute.Defence] = p_preset._defence
	_attributes[Types.Attribute.Accuracy] = p_preset._accuracy
	_attributes[Types.Attribute.Resistance] = p_preset._resistance
	_attributes[Types.Attribute.Mysticism] = p_preset._mysticism
	_attributes[Types.Attribute.Knowledge] = p_preset._knowledge
	_attributes[Types.Attribute.CritChance] = p_preset._critChance
	_attributes[Types.Attribute.CritDamage] = p_preset._critDamage
	
	_currentHealth = GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	
	if(null != p_preset._trait):
		_trait = p_preset._trait.duplicate(true)
		_trait.Init()

func GetEquipmentBonus(p_attribute: Types.Attribute) -> int:
	var bonus_stat: int = 0
	for i: int in _held_items.values():
		bonus_stat += main.GetInstance()._item_collection._items[i]._attributes[p_attribute]
	return bonus_stat

func GetBattleAttributes() -> Dictionary[Types.Attribute, int]:
	var battle_attributes: Dictionary[Types.Attribute, int] = _attributes.duplicate(true)
	for attribute in battle_attributes.keys():
		battle_attributes[attribute] += GetEquipmentBonus(attribute)
	return battle_attributes

func GetBattleAttribute(p_attribute: Types.Attribute) -> int:
	var attribute_val: int = _attributes[p_attribute]
	attribute_val += GetEquipmentBonus(p_attribute)
	return attribute_val

func EquipItem(p_equipment_ID: int) -> void:
	if(not _held_items.has(main.GetInstance()._item_collection._items[p_equipment_ID]._slot)):
		_held_items[main.GetInstance()._item_collection._items[p_equipment_ID]._slot] = p_equipment_ID
	else:
		print(_name + " already has equipment for ", main.GetInstance()._item_collection._items[p_equipment_ID]._slot)

func UnequipItem(p_slot: Types.Slot) -> void:
	_held_items.erase(p_slot)

# Preset Data
var _name: String = ""
var _texture: String = ""
var _normal_map: String = ""

var _rarity: Types.Rarity
var _faction: Types.Faction
var _role: Types.Role

var _instanceID : int = 0
@warning_ignore_start("unused_private_class_variable")
var _experience : int = 0
var _level: int = 1
@warning_ignore_restore("unused_private_class_variable")

var _skills: Array[Skill] = []

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

# Dictionary of [Slot type, item instance ID]
var _held_items: Dictionary[Types.Slot, int]

var _currentHealth: int = 0
var _attributes_weights: AttributeWeightPreset

var _trait: CharacterTrait

@warning_ignore_start("unused_private_class_variable")
var _active_buffs: Array[StatusEffects.Buff] = []
var _active_debuffs: Array[StatusEffects.Debuff] = []
@warning_ignore_restore("unused_private_class_variable")

var _preset_UID: String = ""
