class_name ResourceBar extends Control

const SILVER_TITLE: String = "Silver"
const SILVER_DESCRIPTION: String = "Earned from battles and used to purchase items and upgrades."

const SUPPLIES_TITLE: String = "Supplies"
const SUPPLIES_DESCRIPTION: String = "Spent at Rest Stops to temporarily empower your champions."

const FORTUNES_FAVOR_TITLE: String = "Fortune's Favor"
const FORTUNES_FAVOR_DESCRIPTION: String = "Used to recruit new champions."

const TALLY_TITLE: String = "Tallies"
const TALLY_DESCRIPTION: String = "Earned by releasing champions. Spent at the Tally Board."

@export var _fortunes_favor_UI: FortunesFavorUISlot
@export var _silver_UI: ResourceUISlot
@export var _supplies_UI: ResourceUISlot
@export var _tallies_UI: ResourceUISlot

func _ready() -> void:
	Refresh()
	main.GetInstance()._resources.resources_changed.connect(Refresh)

func Refresh() -> void:
	var resources: ResourceHandler = main.GetInstance()._resources

	_silver_UI.SetText(str(resources._silver))
	_silver_UI.SetTexture(resources.SILVER_COIN_TEXTURE)
	_silver_UI.SetToolTip(SILVER_TITLE, SILVER_DESCRIPTION)

	_supplies_UI.SetText(str(resources._supplies))
	_supplies_UI.SetTexture(resources.SUPPLIES_TEXTURE)
	_supplies_UI.SetToolTip(SUPPLIES_TITLE, SUPPLIES_DESCRIPTION)

	_tallies_UI.SetText(str(resources.GetTallies()))
	_tallies_UI.SetTexture(resources.TALLY_TEXTURE)
	_tallies_UI.SetToolTip(TALLY_TITLE, TALLY_DESCRIPTION)

	var total_fortunes_favor: int = (
			resources.GetFortunesFavor(FortuneFavorTier.TierType.BONE)
			+ resources.GetFortunesFavor(FortuneFavorTier.TierType.BRASS)
			+ resources.GetFortunesFavor(FortuneFavorTier.TierType.PARCHMENT))
	_fortunes_favor_UI.SetMainSlot(
			str(total_fortunes_favor), resources.FORTUNES_FAVOR_BONE_1,
			FORTUNES_FAVOR_TITLE, FORTUNES_FAVOR_DESCRIPTION)

	_fortunes_favor_UI.SetTierSlot(
			FortuneFavorTier.TierType.BONE,
			str(resources.GetFortunesFavor(FortuneFavorTier.TierType.BONE)),
			resources.FORTUNES_FAVOR_BONE_1,
			"Bone Fortune's Favor", FORTUNES_FAVOR_DESCRIPTION)
	_fortunes_favor_UI.SetTierSlot(
			FortuneFavorTier.TierType.BRASS,
			str(resources.GetFortunesFavor(FortuneFavorTier.TierType.BRASS)),
			resources.FORTUNES_FAVOR_BRASS_1,
			"Brass Fortune's Favor", FORTUNES_FAVOR_DESCRIPTION)
	_fortunes_favor_UI.SetTierSlot(
			FortuneFavorTier.TierType.PARCHMENT,
			str(resources.GetFortunesFavor(FortuneFavorTier.TierType.PARCHMENT)),
			resources.FORTUNES_FAVOR_PARCHMENT_1,
			"Parchment Fortune's Favor", FORTUNES_FAVOR_DESCRIPTION)
