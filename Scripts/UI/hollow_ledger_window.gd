class_name HollowLedgerWindow extends Control

const BONE_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Bone_Tier.tres")
const BRASS_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Brass_Tier.tres")
const PARCHMENT_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Parchment_Tier.tres")

const NATURE_PRESETS: Array[AttributeWeightPreset] = [
	preload("res://Data/Attribute_Weights/Arcane.tres"),
	preload("res://Data/Attribute_Weights/Calculating.tres"),
	preload("res://Data/Attribute_Weights/Conjurer.tres"),
	preload("res://Data/Attribute_Weights/Dexterous.tres"),
	preload("res://Data/Attribute_Weights/Fierce.tres"),
	preload("res://Data/Attribute_Weights/Gluttonous.tres"),
	preload("res://Data/Attribute_Weights/Learned.tres"),
	preload("res://Data/Attribute_Weights/Marksman.tres"),
	preload("res://Data/Attribute_Weights/Reckless.tres"),
	preload("res://Data/Attribute_Weights/Resilient.tres"),
	preload("res://Data/Attribute_Weights/Sturdy.tres"),
]

const RARITY_COLORS: Dictionary[Types.Rarity, Color] = {
	Types.Rarity.Common: Color(0.384, 0.384, 0.384, 1.0),
	Types.Rarity.Uncommon: Color(0.0, 0.73, 0.253, 1.0),
	Types.Rarity.Rare: Color(0.178, 0.515, 1.0, 1.0),
	Types.Rarity.Epic: Color(0.582, 0.136, 1.0, 1.0),
	Types.Rarity.Legendary: Color(0.934, 0.254, 0.0, 1.0),
	Types.Rarity.Relic: Color(0.9, 0.0, 0.0, 1.0),
}

@export var _tier_list: VBoxContainer
@export var _background: ColorRect
@export var _nature_option_button: OptionButton
@export var _nature_attribute_list: VBoxContainer

func GetSize() -> Vector2:
	return Vector2(_background.get_rect().size.x, _background.get_rect().size.y)

func Init() -> void:
	for child in _tier_list.get_children():
		child.queue_free()

	for tier in [BONE_TIER, BRASS_TIER, PARCHMENT_TIER]:
		_tier_list.add_child(BuildTierSection(tier))

	_nature_option_button.clear()
	for preset in NATURE_PRESETS:
		_nature_option_button.add_item(preset._name)

	BuildNatureList(NATURE_PRESETS[0])

func BuildTierSection(p_tier: FortuneFavorTier) -> VBoxContainer:
	var section: VBoxContainer = VBoxContainer.new()

	var champion_chance: float = (
			(1.0 - pow(1.0 - RecruitmentManager.CHAMPION_CHANCE_PER_REWARD, p_tier.reward_count)) * 100.0)

	var header: Label = Label.new()
	header.text = ("%s Fortune's Favor - %.1f%%"
			% [FortuneFavorTier.TierType.keys()[p_tier.tier_type], champion_chance])
	header.add_theme_font_size_override("font_size", 18)
	section.add_child(header)

	var grouped: Dictionary[Types.Rarity, Array] = RecruitmentManager.GroupByRarity(p_tier.recruitable_champions)
	var rarity_rates: Dictionary[Types.Rarity, float] = LootManager.GetRarityRates(grouped)
	for rarity in rarity_rates.keys():
		var row: Label = Label.new()
		row.text = "    %s: %.1f%%" % [Types.RarityName(rarity), rarity_rates[rarity]]
		row.add_theme_color_override("font_color", RARITY_COLORS[rarity])
		section.add_child(row)

	return section

func BuildNatureList(p_preset: AttributeWeightPreset) -> void:
	for child in _nature_attribute_list.get_children():
		child.queue_free()

	var weights: Dictionary = p_preset._weights
	var nonzero_values: Array[int] = []
	for weight in weights.values():
		if weight != 0:
			nonzero_values.append(weight)

	var min_nonzero: int = 0
	var max_nonzero: int = 0
	if not nonzero_values.is_empty():
		min_nonzero = nonzero_values.min()
		max_nonzero = nonzero_values.max()

	var attribute_names: Array = Types.Attribute.keys()
	for attribute_index in weights.keys():
		if attribute_index >= attribute_names.size():
			continue
		var weight: int = weights[attribute_index]
		var descriptor: String = DescribeWeight(weight, min_nonzero, max_nonzero)
		var attribute_name: String = attribute_names[attribute_index]

		var row: HBoxContainer = HBoxContainer.new()

		var name_label: Label = Label.new()
		name_label.text = attribute_name
		name_label.custom_minimum_size.x = 140
		if KeyWordColors.KEYWORDS.has(attribute_name):
			name_label.add_theme_color_override("font_color", KeyWordColors.KEYWORDS[attribute_name])
		row.add_child(name_label)

		var value_label: Label = Label.new()
		value_label.text = descriptor
		row.add_child(value_label)

		_nature_attribute_list.add_child(row)

static func DescribeWeight(p_weight: int, p_min: int, p_max: int) -> String:
	if p_weight == 0:
		return "None"
	var weight_range: int = p_max - p_min
	if weight_range == 0:
		return "Medium"
	if p_weight <= p_min + int(0.25 * weight_range):
		return "Low"
	if p_weight >= p_max - int(0.25 * weight_range):
		return "High"
	return "Medium"

func _on_nature_selected(p_index: int) -> void:
	BuildNatureList(NATURE_PRESETS[p_index])

func _on_close_button_up() -> void:
	self.hide()
