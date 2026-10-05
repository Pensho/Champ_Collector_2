class_name ResourceHandler extends Node

signal resources_changed

const SILVER_COIN_TEXTURE = preload("uid://cqc2eqqmdc30j")
const SUPPLIES_TEXTURE = preload("uid://64keags07tr4")
const TALLY_TEXTURE = preload("uid://bmmqvp1iw712t")
const FORTUNES_FAVOR_BONE_1 = preload("uid://d3ribnb76plyc")
const FORTUNES_FAVOR_BRASS_1 = preload("uid://dq3fohqivkweb")
const FORTUNES_FAVOR_PARCHMENT_1 = preload("uid://d1le2k5exvc1b")

var _silver: int
var _supplies: int
var _tallies: int
var _fortunes_favor: Dictionary[FortuneFavorTier.TierType, int] = {
	FortuneFavorTier.TierType.BONE: 0,
	FortuneFavorTier.TierType.BRASS: 0,
	FortuneFavorTier.TierType.PARCHMENT: 0,
}
var _fortunes_favor_pity: Dictionary[FortuneFavorTier.TierType, int] = {
	FortuneFavorTier.TierType.BONE: 0,
	FortuneFavorTier.TierType.BRASS: 0,
	FortuneFavorTier.TierType.PARCHMENT: 0,
}

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

	_fortunes_favor[FortuneFavorTier.TierType.BONE] = 3
	_fortunes_favor[FortuneFavorTier.TierType.BRASS] = 1

func Serialize() -> Dictionary:
	return {
		"silver": _silver,
		"supplies": _supplies,
		"tallies": _tallies,
		"fortunes_favor_bone": _fortunes_favor[FortuneFavorTier.TierType.BONE],
		"fortunes_favor_brass": _fortunes_favor[FortuneFavorTier.TierType.BRASS],
		"fortunes_favor_parchment": _fortunes_favor[FortuneFavorTier.TierType.PARCHMENT],
		"fortunes_favor_pity_bone": _fortunes_favor_pity[FortuneFavorTier.TierType.BONE],
		"fortunes_favor_pity_brass": _fortunes_favor_pity[FortuneFavorTier.TierType.BRASS],
		"fortunes_favor_pity_parchment": _fortunes_favor_pity[FortuneFavorTier.TierType.PARCHMENT],
	}

func Deserialize(p_data: Dictionary) -> void:
	_silver = p_data["silver"]
	_supplies = p_data["supplies"]
	_tallies = p_data.get("tallies", 0)
	if(p_data.has("fortunes_favor_bone")):
		_fortunes_favor[FortuneFavorTier.TierType.BONE] = p_data["fortunes_favor_bone"]
		_fortunes_favor[FortuneFavorTier.TierType.BRASS] = p_data.get("fortunes_favor_brass", 0)
		_fortunes_favor[FortuneFavorTier.TierType.PARCHMENT] = p_data.get("fortunes_favor_parchment", 0)
	else:
		_fortunes_favor[FortuneFavorTier.TierType.BONE] = p_data.get("fortunes_favor", 0)
	_fortunes_favor_pity[FortuneFavorTier.TierType.BONE] = p_data.get("fortunes_favor_pity_bone", 0)
	_fortunes_favor_pity[FortuneFavorTier.TierType.BRASS] = p_data.get("fortunes_favor_pity_brass", 0)
	_fortunes_favor_pity[FortuneFavorTier.TierType.PARCHMENT] = p_data.get("fortunes_favor_pity_parchment", 0)

func SpendSupplies(amount: int) -> bool:
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

func GetFortunesFavorPity(p_tier_type: FortuneFavorTier.TierType) -> int:
	return _fortunes_favor_pity[p_tier_type]

func IncrementFortunesFavorPity(p_tier_type: FortuneFavorTier.TierType) -> void:
	_fortunes_favor_pity[p_tier_type] += 1

func ResetFortunesFavorPity(p_tier_type: FortuneFavorTier.TierType) -> void:
	_fortunes_favor_pity[p_tier_type] = 0

func GetSilver() -> int:
	return _silver

func GetSupplies() -> int:
	return _supplies

func AddSilver(p_amount: int) -> void:
	_silver += p_amount
	resources_changed.emit()

func SpendSilver(p_amount: int) -> bool:
	if (_silver >= p_amount):
		_silver -= p_amount
		resources_changed.emit()
		return true
	return false

func GetTallies() -> int:
	return _tallies

func AddTallies(p_amount: int) -> void:
	_tallies += p_amount
	resources_changed.emit()

func SpendTallies(p_amount: int) -> bool:
	if (_tallies >= p_amount):
		_tallies -= p_amount
		resources_changed.emit()
		return true
	return false
