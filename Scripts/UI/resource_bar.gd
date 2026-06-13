class_name ResourceBar extends Control

const SILVER_TITLE: String = "Silver"
const SILVER_DESCRIPTION: String = "Earned from battles and used to purchase items and upgrades."

const SUPPLIES_TITLE: String = "Supplies"
const SUPPLIES_DESCRIPTION: String = "Spend to run content. Half are refunded if the player loses a battle."

const FORTUNES_FAVOR_TITLE: String = "Fortune's Favor"
const FORTUNES_FAVOR_DESCRIPTION: String = "Used to recruit new champions."

const SUPPLY_REGEN_COUNTDOWN_COLOR: String = "#E6D29E" # pale gold

@export var _fortunes_favor_UI: ResourceUISlot
@export var _silver_UI: ResourceUISlot
@export var _supplies_UI: ResourceUISlot

func _ready() -> void:
	Refresh()
	main.GetInstance()._resources.resources_changed.connect(Refresh)

	var tooltip_timer: Timer = Timer.new()
	tooltip_timer.wait_time = 1.0
	tooltip_timer.autostart = true
	tooltip_timer.timeout.connect(_RefreshSuppliesTooltip)
	add_child(tooltip_timer)

func Refresh() -> void:
	var resources: ResourceHandler = main.GetInstance()._resources

	_silver_UI.SetText(str(resources._silver))
	_silver_UI.SetTexture(resources.SILVER_COIN_TEXTURE)
	_silver_UI.SetToolTip(SILVER_TITLE, SILVER_DESCRIPTION)

	_supplies_UI.SetText(str(resources._supplies) + "/" + str(GameBalance.MAX_SUPPLIES))
	_supplies_UI.SetTexture(resources.SUPPLIES_TEXTURE)
	_RefreshSuppliesTooltip()

	_fortunes_favor_UI.SetText(str(resources._fortunes_favor))
	_fortunes_favor_UI.SetTexture(resources.FORTUNES_FAVOR_BONE_1)
	_fortunes_favor_UI.SetToolTip(FORTUNES_FAVOR_TITLE, FORTUNES_FAVOR_DESCRIPTION)

func _RefreshSuppliesTooltip() -> void:
	var resources: ResourceHandler = main.GetInstance()._resources
	var description: String = SUPPLIES_DESCRIPTION
	var seconds_left: int = resources.GetSecondsUntilNextSupply()
	if seconds_left > 0:
		@warning_ignore("integer_division")
		var minutes: int = seconds_left / 60
		var seconds: int = seconds_left % 60
		description += "\n[color=%s]Next +%d in %02d:%02d[/color]" % [
				SUPPLY_REGEN_COUNTDOWN_COLOR, GameBalance.SUPPLY_REGEN_AMOUNT, minutes, seconds]
	_supplies_UI.SetToolTip(SUPPLIES_TITLE, description)
