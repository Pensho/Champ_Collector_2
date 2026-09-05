class_name TallyBoardHandler extends Node

signal stock_changed

const BONE_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Bone_Tier.tres")
const BRASS_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Brass_Tier.tres")
const PARCHMENT_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Parchment_Tier.tres")

var _offers: Array[Dictionary] = []
var _restock_anchor_unix: int = 0

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

static func IsRestockDue(p_anchor_unix: int, p_now_unix: int) -> bool:
	if(p_anchor_unix <= 0):
		return true
	return (p_now_unix - p_anchor_unix) >= GameBalance.TALLY_BOARD_RESTOCK_INTERVAL_SECONDS

static func GetSecondsUntilRestock(p_anchor_unix: int, p_now_unix: int) -> int:
	if(IsRestockDue(p_anchor_unix, p_now_unix)):
		return 0
	return GameBalance.TALLY_BOARD_RESTOCK_INTERVAL_SECONDS - (p_now_unix - p_anchor_unix)

static func GetPrice(p_rarity: Types.Rarity) -> int:
	return GameBalance.TALLY_BOARD_PRICE_PER_RARITY[p_rarity]

static func GetRecruitableChampions() -> Array[CharacterPreset]:
	var seen_names: Dictionary[String, bool] = {}
	var champions: Array[CharacterPreset] = []
	for tier: FortuneFavorTier in [BONE_TIER, BRASS_TIER, PARCHMENT_TIER]:
		for preset: CharacterPreset in tier.recruitable_champions:
			if(not seen_names.has(preset._name)):
				seen_names[preset._name] = true
				champions.append(preset)
	return champions

static func RollOffers() -> Array[Dictionary]:
	var pool: Array[CharacterPreset] = GetRecruitableChampions()
	pool.shuffle()

	var offers: Array[Dictionary] = []
	for i in mini(GameBalance.TALLY_BOARD_SLOTS, pool.size()):
		var preset: CharacterPreset = pool[i]
		offers.append({
			"preset_path": preset._preset_path,
			"rarity": preset._rarity,
			"price": GetPrice(preset._rarity),
			"sold_out": false,
		})
	return offers

func EnsureFresh() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	if(not IsRestockDue(_restock_anchor_unix, now)):
		return
	_offers = RollOffers()
	_restock_anchor_unix = now
	stock_changed.emit()

func Purchase(p_index: int) -> bool:
	var entry: Dictionary = _offers[p_index]
	if(entry["sold_out"]):
		return false
	if(main.GetInstance()._character_collection.IsTheCollectionFull()):
		return false
	if(not main.GetInstance()._resources.SpendTallies(entry["price"])):
		return false

	var preset: CharacterPreset = load(entry["preset_path"])
	main.GetInstance()._character_collection.Add(preset)
	entry["sold_out"] = true
	return true

func Serialize() -> Dictionary:
	return {
		"offers": _offers.duplicate(true),
		"restock_anchor_unix": _restock_anchor_unix,
	}

func Deserialize(p_data: Dictionary) -> void:
	if(not p_data.has("offers")):
		print("No Tally Board offers found in save slot.")
		return

	_offers.clear()
	for entry in p_data["offers"]:
		_offers.append({
			"preset_path": String(entry["preset_path"]),
			"rarity": int(entry["rarity"]),
			"price": int(entry["price"]),
			"sold_out": bool(entry["sold_out"]),
		})
	_restock_anchor_unix = int(p_data.get("restock_anchor_unix", 0))
