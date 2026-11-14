class_name ItemSubType extends Resource

## A standard item's kind within its slot. It names the item and grants its implicit.

@warning_ignore_start("unused_private_class_variable")

@export var _name: String = ""
@export var _slot: Types.Slot
@export var _implicit: ItemImplicit = null

@warning_ignore_restore("unused_private_class_variable")

## A Relic never carries an implicit, even when built from a sub-typed preset.
static func ActiveImplicit(p_sub_type: ItemSubType, p_item_type: Types.Item_Type) -> ItemImplicit:
	if(null == p_sub_type or Types.Item_Type.Relic == p_item_type):
		return null
	return p_sub_type._implicit
