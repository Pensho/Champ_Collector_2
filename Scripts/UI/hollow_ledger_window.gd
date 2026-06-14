class_name HollowLedgerWindow extends Control

const BONE_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Bone_Tier.tres")
const BRASS_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Brass_Tier.tres")
const PARCHMENT_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Parchment_Tier.tres")

const RARITY_COLORS: Dictionary[Types.Rarity, Color] = {
	Types.Rarity.Common: Color(0.384, 0.384, 0.384, 1.0),
	Types.Rarity.Uncommon: Color(0.0, 0.544, 0.313, 1.0),
	Types.Rarity.Rare: Color(0.003, 0.152, 0.701, 1.0),
	Types.Rarity.Epic: Color(0.413, 0.0, 0.484, 1.0),
	Types.Rarity.Legendary: Color(0.651, 0.381, 0.0, 1.0),
	Types.Rarity.Relic: Color(0.606, 0.0, 0.0, 1.0),
}

@export var _tier_list: VBoxContainer
@export var _background: ColorRect

func GetSize() -> Vector2:
	return Vector2(_background.get_rect().size.x, _background.get_rect().size.y)

func Init() -> void:
	for child in _tier_list.get_children():
		child.queue_free()

	for tier in [BONE_TIER, BRASS_TIER, PARCHMENT_TIER]:
		_tier_list.add_child(BuildTierSection(tier))

func BuildTierSection(p_tier: FortuneFavorTier) -> VBoxContainer:
	var section: VBoxContainer = VBoxContainer.new()

	var champion_chance: float = (1.0 - pow(1.0 - RecruitmentManager.CHAMPION_CHANCE_PER_REWARD, p_tier.reward_count)) * 100.0

	var header: Label = Label.new()
	header.text = "%s Fortune's Favor - %.1f%%" % [FortuneFavorTier.TierType.keys()[p_tier.tier_type], champion_chance]
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

func _on_close_button_up() -> void:
	self.hide()
