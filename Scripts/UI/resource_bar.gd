class_name ResourceBar extends Control

const SILVER_TITLE: String = "Silver"
const SILVER_DESCRIPTION: String = "The main currency. Earned from battles and used to purchase items and upgrades."

const SUPPLIES_TITLE: String = "Supplies"
const SUPPLIES_DESCRIPTION: String = "Used to run playable content. Each encounter costs supplies to enter, and half are refunded if the player loses."

const FORTUNES_FAVOR_TITLE: String = "Fortune's Favor"
const FORTUNES_FAVOR_DESCRIPTION: String = "Used at the Adventurer's Guild to recruit new champions."

@export var _fortunes_favor_UI: ResourceUISlot
@export var _silver_UI: ResourceUISlot
@export var _supplies_UI: ResourceUISlot

func _ready() -> void:
	Refresh()

func Refresh() -> void:
	var resources: ResourceHandler = main.GetInstance()._resources

	_silver_UI.SetText(str(resources._silver))
	_silver_UI.SetTexture(resources.SILVER_COIN_TEXTURE)
	_silver_UI.SetToolTip(SILVER_TITLE, SILVER_DESCRIPTION)

	_supplies_UI.SetText(str(resources._supplies) + "/" + str(GameBalance.MAX_SUPPLIES))
	_supplies_UI.SetTexture(resources.SUPPLIES_TEXTURE)
	_supplies_UI.SetToolTip(SUPPLIES_TITLE, SUPPLIES_DESCRIPTION)

	_fortunes_favor_UI.SetText(str(resources._fortunes_favor))
	_fortunes_favor_UI.SetTexture(resources.FORTUNES_FAVOR_BONE_1)
	_fortunes_favor_UI.SetToolTip(FORTUNES_FAVOR_TITLE, FORTUNES_FAVOR_DESCRIPTION)
