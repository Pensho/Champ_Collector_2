class_name ResourceHandler extends Node

const SILVER_COIN_TEXTURE = preload("uid://cqc2eqqmdc30j")
const SUPPLIES_TEXTURE = preload("uid://64keags07tr4")
const FORTUNES_FAVOR_BONE_1 = preload("uid://d3ribnb76plyc")
const FORTUNES_FAVOR_BRASS_1 = preload("uid://dq3fohqivkweb")
const FORTUNES_FAVOR_PARCHMENT_1 = preload("uid://d1le2k5exvc1b")

signal resources_changed

var _silver: int
var _supplies: int
var _fortunes_favor: Dictionary[FortuneFavorTier.TierType, int] = {
	FortuneFavorTier.TierType.BONE: 0,
	FortuneFavorTier.TierType.BRASS: 0,
	FortuneFavorTier.TierType.PARCHMENT: 0,
}
var _last_supply_update_unix: int

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(UpdateSupplies)
	add_child(timer)
	
	_supplies = GameBalance.MAX_SUPPLIES

func Serialize() -> Dictionary:
	return {
		"silver": _silver,
		"supplies": _supplies,
		"fortunes_favor_bone": _fortunes_favor[FortuneFavorTier.TierType.BONE],
		"fortunes_favor_brass": _fortunes_favor[FortuneFavorTier.TierType.BRASS],
		"fortunes_favor_parchment": _fortunes_favor[FortuneFavorTier.TierType.PARCHMENT],
		"last_supply_update_unix": _last_supply_update_unix,
	}

func Deserialize(p_data: Dictionary) -> void:
	_silver = p_data["silver"]
	_supplies = p_data["supplies"]
	if(p_data.has("fortunes_favor_bone")):
		_fortunes_favor[FortuneFavorTier.TierType.BONE] = p_data["fortunes_favor_bone"]
		_fortunes_favor[FortuneFavorTier.TierType.BRASS] = p_data.get("fortunes_favor_brass", 0)
		_fortunes_favor[FortuneFavorTier.TierType.PARCHMENT] = p_data.get("fortunes_favor_parchment", 0)
	else:
		_fortunes_favor[FortuneFavorTier.TierType.BONE] = p_data.get("fortunes_favor", 0)
	_last_supply_update_unix = p_data.get("last_supply_update_unix", 0)
	UpdateSupplies()

## Computes supply regeneration based on elapsed real time, preserving partial
## progress toward the next increment as the new anchor time.
static func ComputeSupplyRegen(p_supplies: int, p_last_unix: int, p_now_unix: int) -> Dictionary:
	if p_supplies >= GameBalance.MAX_SUPPLIES:
		return {"supplies": p_supplies, "last_unix": p_now_unix}
	if p_last_unix <= 0:
		return {"supplies": p_supplies, "last_unix": p_now_unix}

	var elapsed: int = p_now_unix - p_last_unix
	if elapsed < GameBalance.SUPPLY_REGEN_INTERVAL_SECONDS:
		return {"supplies": p_supplies, "last_unix": p_last_unix}

	var increments: int = elapsed / GameBalance.SUPPLY_REGEN_INTERVAL_SECONDS
	var gained: int = increments * GameBalance.SUPPLY_REGEN_AMOUNT
	var new_supplies: int = mini(GameBalance.MAX_SUPPLIES, p_supplies + gained)

	var new_last_unix: int
	if new_supplies >= GameBalance.MAX_SUPPLIES:
		new_last_unix = p_now_unix
	else:
		new_last_unix = p_last_unix + increments * GameBalance.SUPPLY_REGEN_INTERVAL_SECONDS

	return {"supplies": new_supplies, "last_unix": new_last_unix}

func UpdateSupplies() -> void:
	var result: Dictionary = ComputeSupplyRegen(
			_supplies, _last_supply_update_unix, int(Time.get_unix_time_from_system()))
	var changed: bool = result["supplies"] != _supplies
	_supplies = result["supplies"]
	_last_supply_update_unix = result["last_unix"]
	if changed:
		resources_changed.emit()

func GetSecondsUntilNextSupply() -> int:
	if _supplies >= GameBalance.MAX_SUPPLIES:
		return 0
	var elapsed: int = int(Time.get_unix_time_from_system()) - _last_supply_update_unix
	return GameBalance.SUPPLY_REGEN_INTERVAL_SECONDS - (elapsed % GameBalance.SUPPLY_REGEN_INTERVAL_SECONDS)

func SpendSupplies(amount: int) -> bool:
	UpdateSupplies()
	if (_supplies >= amount):
		_supplies -= amount
		resources_changed.emit()
		return true
	return false

func AddSupplies(p_amount: int) -> void:
	_supplies = _supplies + p_amount
	resources_changed.emit()

func GetFortunesFavor(p_tier_type: FortuneFavorTier.TierType) -> int:
	return _fortunes_favor[p_tier_type]

func AddFortunesFavor(p_tier_type: FortuneFavorTier.TierType, p_amount: int) -> void:
	_fortunes_favor[p_tier_type] += p_amount
	resources_changed.emit()

func SpendFortunesFavor(p_tier_type: FortuneFavorTier.TierType, p_amount: int) -> bool:
	if (_fortunes_favor[p_tier_type] >= p_amount):
		_fortunes_favor[p_tier_type] -= p_amount
		resources_changed.emit()
		return true
	return false

func AddSilver(p_amount: int) -> void:
	_silver += p_amount
	resources_changed.emit()

func SpendSilver(p_amount: int) -> bool:
	if (_silver >= p_amount):
		_silver -= p_amount
		resources_changed.emit()
		return true
	return false
