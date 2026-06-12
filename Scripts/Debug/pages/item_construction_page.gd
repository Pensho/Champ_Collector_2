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
@export var _slot_option: OptionButton
@export var _rarity_option: OptionButton
@export var _attribute_spins: Array[SpinBox]

func _ready() -> void:
	page_title = "Item Construction"
	for slot_name in Types.Slot.keys():
		_slot_option.add_item(slot_name, Types.Slot[slot_name])
	for rarity_name in Types.Rarity.keys():
		_rarity_option.add_item(rarity_name, Types.Rarity[rarity_name])
	for spin in _attribute_spins:
		spin.min_value = -ATTRIBUTE_RANGE
		spin.max_value = ATTRIBUTE_RANGE

func _on_add_to_collection_button_up() -> void:
	var attributes: Dictionary[Types.Attribute, int] = {}
	for i in ATTRIBUTE_ORDER.size():
		attributes[ATTRIBUTE_ORDER[i]] = int(_attribute_spins[i].value)

	var item_name: String = _name_edit.text.strip_edges()
	if(item_name.is_empty()):
		item_name = "Debug Item"

	var slot: Types.Slot = _slot_option.get_selected_id() as Types.Slot
	var rarity: Types.Rarity = _rarity_option.get_selected_id() as Types.Rarity
	var preset: EquipmentPreset = DebugActions.build_equipment_preset(item_name, slot, rarity, attributes)
	main.GetInstance()._item_collection.AddPreset(preset)
