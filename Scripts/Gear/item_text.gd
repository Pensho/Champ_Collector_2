class_name ItemText extends RefCounted

## An item's description split into the parts item tooltips and popups lay out separately.

## The item type line shown under the name.
var subtitle: String = ""
## Empty for an item without an implicit.
var implicit: String = ""
## Rolled attributes, then a Relic's effect.
var body: String = ""

static func Build(
		p_slot: Types.Slot,
		p_item_type: Types.Item_Type,
		p_rarity: Types.Rarity,
		p_attributes: Dictionary[Types.Attribute, int],
		p_relic_effect: RelicEffect = null,
		p_sub_type: ItemSubType = null) -> ItemText:
	var item_text: ItemText = ItemText.new()
	item_text.subtitle = Types.Slot.keys()[p_slot]
	if(Types.Item_Type.Relic == p_item_type):
		item_text.subtitle = "Relic " + item_text.subtitle
	var implicit: ItemImplicit = ItemSubType.ActiveImplicit(p_sub_type, p_item_type)
	if(null != implicit):
		item_text.implicit = implicit.Text(p_rarity)
	var lines: Array[String] = []
	for attribute in p_attributes.keys():
		if(0 != p_attributes[attribute]):
			lines.append(AttributeLine(attribute, p_attributes[attribute]))
	item_text.body = "\n".join(lines)
	if(null != p_relic_effect):
		item_text.body += "\n\n" + p_relic_effect._body
	return item_text

## For an item not yet created from its preset, such as a drop or shop stock.
## A Relic's text is only written by Init, so a copy is initialised at the item's rarity.
static func ForPreset(
		p_preset: EquipmentPreset, p_item_type: Types.Item_Type, p_rarity: Types.Rarity,
		p_attributes: Dictionary[Types.Attribute, int]) -> ItemText:
	var relic_effect: RelicEffect = null
	if(null != p_preset._relic_effect):
		relic_effect = p_preset._relic_effect.duplicate(true)
		relic_effect.Init(p_rarity)
	return Build(p_preset._slot, p_item_type, p_rarity, p_attributes, relic_effect, p_preset._sub_type)

static func AttributeLine(p_attribute: Types.Attribute, p_value: int) -> String:
	return "%s %+d" % [Types.Attribute.keys()[p_attribute], p_value]
