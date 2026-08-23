class_name Character extends RefCounted

# Preset Data
var _name: String = ""
var _texture: String = ""
var _normal_map: String = ""

var _rarity: Types.Rarity
var _faction: Types.Faction
var _role: Types.Role

var _instance_ID : int = 0
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

var _current_health: int = 0
var _attributes_weights: AttributeWeightPreset

var _trait: CharacterTrait

## The effect this character offers to a Symbiote that grafts onto it (enemies only).
var _graft_effect: GraftEffect = null

## The effect this character has received by grafting onto something else (Symbiotes only).
var _graft: GraftEffect = null
var _graft_UID: String = ""

@warning_ignore_start("unused_private_class_variable")
var _active_buffs: Array[StatusEffects.Buff] = []
var _active_debuffs: Array[StatusEffects.Debuff] = []
@warning_ignore_restore("unused_private_class_variable")

var _preset_path: String = ""

func InstantiateNew(p_preset: CharacterPreset, p_instance_ID: int) -> void:
	_instance_ID = p_instance_ID
	_preset_path = p_preset._preset_path
	
	_name = p_preset._name
	_texture = p_preset._texture
	_normal_map = p_preset._normal_map
	_rarity = p_preset._rarity
	_faction = p_preset._faction
	_role = p_preset._role
	_graft_effect = p_preset._graft_effect
	# Deep-duplicate each skill so every Character owns its own Skill instances.
	# Sharing the preset's skills by reference leaks mutable state (cooldown_left)
	# between enemies of the same variant and across battles in the same session.
	_skills = []
	for skill: Skill in p_preset._skills:
		_skills.append(skill.duplicate(true))
	if(!p_preset._attribute_weight_types_available.is_empty()):
		var weight_index: int = randi_range(0, p_preset._attribute_weight_types_available.size() - 1)
		_attributes_weights = p_preset._attribute_weight_types_available[weight_index].duplicate(true)
	
	_attributes[Types.Attribute.Health] = p_preset._health
	_attributes[Types.Attribute.Speed] = p_preset._speed
	_attributes[Types.Attribute.Attack] = p_preset._attack
	_attributes[Types.Attribute.Defence] = p_preset._defence
	_attributes[Types.Attribute.Accuracy] = p_preset._accuracy
	_attributes[Types.Attribute.Resistance] = p_preset._resistance
	_attributes[Types.Attribute.Mysticism] = p_preset._mysticism
	_attributes[Types.Attribute.Knowledge] = p_preset._knowledge
	_attributes[Types.Attribute.CritChance] = p_preset._critical_chance
	_attributes[Types.Attribute.CritDamage] = p_preset._critical_damage

	_current_health = GetTotalAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	
	if(null != p_preset._trait):
		_trait = p_preset._trait.duplicate(true)
		_trait.Init(_rarity)

func GetEquipmentBonus(p_attribute: Types.Attribute) -> int:
	var bonus_stat: int = 0
	for i: int in _held_items.values():
		bonus_stat += main.GetInstance()._item_collection._items[i]._attributes[p_attribute]
	return bonus_stat

## This character's own trait, if any, followed by every equipped item's Relic effect —
## every source a combat hook can fire from (Concept_Document.md 3.3.1).
func HookSources() -> Array[CharacterTrait]:
	var sources: Array[CharacterTrait] = []
	if(null != _trait):
		sources.append(_trait)
	for equipment_ID: int in _held_items.values():
		var relic_effect: RelicEffect = main.GetInstance()._item_collection._items[equipment_ID]._relic_effect
		if(null != relic_effect):
			sources.append(relic_effect)
	return sources

func GetBaseAttributes() -> Dictionary[Types.Attribute, int]:
	return _attributes.duplicate(true)

func ApplyEquipmentBonuses(p_attributes: Dictionary[Types.Attribute, int]) -> void:
	for attribute in p_attributes.keys():
		p_attributes[attribute] += GetEquipmentBonus(attribute)

func ApplyTraitAttributeBonus(p_attributes: Dictionary[Types.Attribute, int]) -> void:
	var sources: Array[CharacterTrait] = HookSources()
	for attribute in p_attributes.keys():
		var base_value: int = p_attributes[attribute]
		for source: CharacterTrait in sources:
			p_attributes[attribute] += source.GetAttributeDelta(attribute, base_value)

func GetTotalAttributes() -> Dictionary[Types.Attribute, int]:
	var attributes: Dictionary[Types.Attribute, int] = GetBaseAttributes()
	ApplyEquipmentBonuses(attributes)
	ApplyTraitAttributeBonus(attributes)
	return attributes

func GetTotalAttribute(p_attribute: Types.Attribute) -> int:
	return GetTotalAttributes()[p_attribute]

func ApplyGraft(p_graft_effect: GraftEffect) -> void:
	_graft = p_graft_effect.duplicate(true)
	_graft.Init(_rarity)
	_trait = _graft
	_graft_UID = p_graft_effect.resource_path

func EquipItem(p_equipment_ID: int) -> void:
	if(not _held_items.has(main.GetInstance()._item_collection._items[p_equipment_ID]._slot)):
		_held_items[main.GetInstance()._item_collection._items[p_equipment_ID]._slot] = p_equipment_ID
	else:
		print(_name + " already has equipment for ", main.GetInstance()._item_collection._items[p_equipment_ID]._slot)

func UnequipItem(p_slot: Types.Slot) -> void:
	_held_items.erase(p_slot)
