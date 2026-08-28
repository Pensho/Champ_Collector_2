class_name RewardSummaryUI extends Control

const REWARD_ITEM_SLOT_SCENE: PackedScene = preload("res://Scenes/ui/Post_Battle_Menu/Reward_Item_Slot.tscn")
const FORTUNES_FAVOR_ICONS: Dictionary[FortuneFavorTier.TierType, Texture2D] = {
	FortuneFavorTier.TierType.BONE: ResourceHandler.FORTUNES_FAVOR_BONE_1,
	FortuneFavorTier.TierType.BRASS: ResourceHandler.FORTUNES_FAVOR_BRASS_1,
	FortuneFavorTier.TierType.PARCHMENT: ResourceHandler.FORTUNES_FAVOR_PARCHMENT_1,
}

@export var _label_experience: Label
@export var _label_silver: Label
@export var _label_supplies: Label
@export var _h_box_container_items: HBoxContainer

func SetRewards(p_drop_result: LootTable.DropResult) -> void:
	_SetOptionalLabel(_label_experience, "Experience: ", p_drop_result._experience)
	_SetOptionalLabel(_label_silver, "Silver: ", p_drop_result._silver)
	_SetOptionalLabel(_label_supplies, "Supplies: ", p_drop_result._supplies)

	for child in _h_box_container_items.get_children():
		child.queue_free()

	if(null != p_drop_result._equipment):
		_AddEquipmentSlot(p_drop_result._equipment)
	for tier in p_drop_result._fortunes_favor.keys():
		_AddFortunesFavorSlot(tier, p_drop_result._fortunes_favor[tier])

	var reagent_counts: Dictionary[String, int] = {}
	for reagent_key in p_drop_result._reagents:
		reagent_counts[reagent_key] = reagent_counts.get(reagent_key, 0) + 1
	for reagent_key in reagent_counts.keys():
		_AddReagentSlot(reagent_key, reagent_counts[reagent_key])

	visible = (
			0 < p_drop_result._experience
			or 0 < p_drop_result._silver
			or 0 < p_drop_result._supplies
			or null != p_drop_result._equipment
			or not reagent_counts.is_empty()
			or _HasAnyFortunesFavor(p_drop_result))

func _HasAnyFortunesFavor(p_drop_result: LootTable.DropResult) -> bool:
	for tier in p_drop_result._fortunes_favor.keys():
		if(0 < p_drop_result._fortunes_favor[tier]):
			return true
	return false

func _SetOptionalLabel(p_label: Label, p_prefix: String, p_value: int) -> void:
	p_label.visible = 0 < p_value
	p_label.text = p_prefix + str(p_value)

func _AddEquipmentSlot(p_equipment: EquipmentPreset) -> void:
	var slot: RewardItemSlotUI = REWARD_ITEM_SLOT_SCENE.instantiate()
	_h_box_container_items.add_child(slot)
	slot.SetTexture(load(p_equipment._texture_path))
	slot.SetCount("")
	slot.SetToolTip(
			p_equipment._name + " (" + Types.RarityName(p_equipment._rarity) + ")",
			Equipment.DescriptionText(p_equipment._slot, p_equipment._attributes, p_equipment._relic_effect))

func _AddReagentSlot(p_reagent_key: String, p_count: int) -> void:
	var reagent: ReagentData = ReagentRegistry.Get(p_reagent_key)
	var slot: RewardItemSlotUI = REWARD_ITEM_SLOT_SCENE.instantiate()
	_h_box_container_items.add_child(slot)
	slot.SetTexture(reagent.icon)
	slot.SetCount(str(p_count))
	slot.SetToolTip(reagent.display_name, reagent.description)

func _AddFortunesFavorSlot(p_tier: FortuneFavorTier.TierType, p_count: int) -> void:
	if(0 >= p_count):
		return
	var slot: RewardItemSlotUI = REWARD_ITEM_SLOT_SCENE.instantiate()
	_h_box_container_items.add_child(slot)
	slot.SetTexture(FORTUNES_FAVOR_ICONS[p_tier])
	slot.SetCount(str(p_count))
	slot.SetToolTip(FortuneFavorTier.TierType.keys()[p_tier], "Used to recruit new champions.")
