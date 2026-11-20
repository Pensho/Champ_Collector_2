extends DebugPage

const ATTRIBUTE_RANGE: int = 999

## Index matches the SpinBox order in _attribute_spins.
const ATTRIBUTE_ORDER: Array[Types.Attribute] = [
	Types.Attribute.Health,
	Types.Attribute.Speed,
	Types.Attribute.Attack,
	Types.Attribute.Defence,
	Types.Attribute.Accuracy,
	Types.Attribute.Resistance,
	Types.Attribute.Mysticism,
	Types.Attribute.Knowledge,
	Types.Attribute.CritChance,
	Types.Attribute.CritDamage,
]

@export var _name_edit: LineEdit
## Lists every standard preset by sub-type; the selected ID indexes _sub_type_keys.
@export var _sub_type_option: OptionButton
@export var _rarity_option: OptionButton
@export var _attribute_spins: Array[SpinBox]

var _sub_type_keys: Array[String] = []

func _ready() -> void:
	page_title = "Item Construction"
	for key in EquipmentPresetRegistry.PRESETS.keys():
		var preset: EquipmentPreset = EquipmentPresetRegistry.PRESETS[key]
		_sub_type_option.add_item(
				"%s (%s)" % [preset._sub_type._name, Types.Slot.keys()[preset._slot]], _sub_type_keys.size())
		_sub_type_keys.append(key)
	for rarity_name in Types.Rarity.keys():
		_rarity_option.add_item(rarity_name, Types.Rarity[rarity_name])
	for spin in _attribute_spins:
		spin.min_value = -ATTRIBUTE_RANGE
		spin.max_value = ATTRIBUTE_RANGE

func _on_add_to_collection_pressed() -> void:
	var attributes: Dictionary[Types.Attribute, int] = {}
	for i in ATTRIBUTE_ORDER.size():
		attributes[ATTRIBUTE_ORDER[i]] = int(_attribute_spins[i].value)

	var item_name: String = _name_edit.text.strip_edges()
	if(item_name.is_empty()):
		item_name = "Debug Item"

	var base_preset: EquipmentPreset = EquipmentPresetRegistry.Get(_sub_type_keys[_sub_type_option.get_selected_id()])
	var rarity: Types.Rarity = _rarity_option.get_selected_id() as Types.Rarity
	var preset: EquipmentPreset = DebugActions.build_equipment_preset(item_name, base_preset, rarity, attributes)
	main.GetInstance()._item_collection.AddPreset(preset)

func _on_grant_all_relics_pressed() -> void:
	DebugActions.grant_all_implemented_relics(main.GetInstance()._item_collection, Types.Rarity.Uncommon)
