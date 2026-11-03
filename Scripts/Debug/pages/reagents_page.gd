extends DebugPage

const MAXIMUM_QUANTITY: int = 99

@export var _family_option: OptionButton
@export var _rarity_option: OptionButton
@export var _quantity_spin: SpinBox
@export var _owned_label: Label

var _families: Array[String] = []

func _ready() -> void:
	page_title = "Reagents"
	_quantity_spin.min_value = 1
	_quantity_spin.max_value = MAXIMUM_QUANTITY
	_families = DebugCatalog.GetReagentFamilies()
	for family in _families:
		_family_option.add_item(family.replace("_", " "))
	_RefreshRarityOptions()

func Refresh() -> void:
	var lines: Array[String] = []
	var owned: Dictionary[String, int] = main.GetInstance()._reagent_collection.GetAllOwned()
	var owned_keys: Array[String] = []
	owned_keys.assign(owned.keys())
	owned_keys.sort()
	for reagent_key in owned_keys:
		lines.append(reagent_key.replace("_", " ") + ": " + str(owned[reagent_key]))
	if(lines.is_empty()):
		_owned_label.text = "No reagents owned."
	else:
		_owned_label.text = "\n".join(lines)

func _RefreshRarityOptions() -> void:
	_rarity_option.clear()
	if(_families.is_empty()):
		return
	for rarity in DebugCatalog.GetReagentRarities(_families[_family_option.selected]):
		_rarity_option.add_item(Types.Rarity.find_key(rarity), rarity)

func _on_family_selected(_p_index: int) -> void:
	_RefreshRarityOptions()

func _on_add_to_inventory_button_up() -> void:
	if(_families.is_empty() or _rarity_option.selected < 0):
		return
	DebugActions.grant_reagent(main.GetInstance()._reagent_collection, _families[_family_option.selected],
			_rarity_option.get_selected_id() as Types.Rarity, int(_quantity_spin.value))
	Refresh()
