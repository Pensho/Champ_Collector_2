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
}

@export var _tier_list: VBoxContainer
@export var _background: ColorRect
@export var _nature_option_button: OptionButton
@export var _nature_attribute_list: VBoxContainer
@export var _glossary_list: VBoxContainer

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
	BuildGlossary()

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

func BuildGlossary() -> void:
	for child in _glossary_list.get_children():
		child.queue_free()

	_glossary_list.add_child(BuildGlossaryHeader("Buffs"))
	for buff_name in Types.Buff_Type.keys():
		var buff_type: Types.Buff_Type = Types.Buff_Type[buff_name]
		if(Types.Buff_Type.Invalid == buff_type):
			continue
		_glossary_list.add_child(BuildGlossaryRow(
				StatusEffectRegistry.BuffData(buff_type), Types.BuffName(buff_type)))

	_glossary_list.add_child(BuildGlossaryHeader("Debuffs"))
	for debuff_name in Types.Debuff_Type.keys():
		var debuff_type: Types.Debuff_Type = Types.Debuff_Type[debuff_name]
		if(Types.Debuff_Type.Invalid == debuff_type):
			continue
		_glossary_list.add_child(BuildGlossaryRow(
				StatusEffectRegistry.DebuffData(debuff_type), Types.DebuffName(debuff_type)))

func BuildGlossaryHeader(p_text: String) -> Label:
	var header: Label = Label.new()
	header.text = p_text
	header.add_theme_font_size_override("font_size", 18)
	return header

func BuildGlossaryRow(p_data: StatusEffectData, p_display_name: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()

	var icon: TextureRect = TextureRect.new()
	icon.texture = p_data.icon
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var text_column: VBoxContainer = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label: Label = Label.new()
	name_label.text = p_display_name
	if KeyWordColors.KEYWORDS.has(p_display_name):
		name_label.add_theme_color_override("font_color", KeyWordColors.KEYWORDS[p_display_name])
	text_column.add_child(name_label)

	# A plain autowrap Label, not a RichTextLabel: dozens of fit_content
	# RichTextLabels inside this nested ScrollContainer chain blow out Godot's
	# deferred-update message queue and crash the engine.
	var description_label: Label = Label.new()
	description_label.text = p_data.description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(description_label)

	row.add_child(text_column)
	return row

func _on_nature_selected(p_index: int) -> void:
	BuildNatureList(NATURE_PRESETS[p_index])

func _on_close_button_up() -> void:
	self.hide()
