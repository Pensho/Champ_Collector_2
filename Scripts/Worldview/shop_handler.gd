class_name ShopHandler extends Node

signal stock_changed

var _stock: Array[Dictionary] = []
var _restock_anchor_unix: int = 0
var _favor_purchase_unix: int = 0

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

static func IsRestockDue(p_anchor_unix: int, p_now_unix: int) -> bool:
	if(p_anchor_unix <= 0):
		return true
	return (p_now_unix - p_anchor_unix) >= GameBalance.SHOP_RESTOCK_INTERVAL_SECONDS

static func GetSecondsUntilRestock(p_anchor_unix: int, p_now_unix: int) -> int:
	if(IsRestockDue(p_anchor_unix, p_now_unix)):
		return 0
	return GameBalance.SHOP_RESTOCK_INTERVAL_SECONDS - (p_now_unix - p_anchor_unix)

static func IsFavorAvailable(p_last_purchase_unix: int, p_now_unix: int) -> bool:
	if(p_last_purchase_unix <= 0):
		return true
	return (p_now_unix - p_last_purchase_unix) >= GameBalance.SHOP_FORTUNES_FAVOR_COOLDOWN_SECONDS

static func GetSecondsUntilFavor(p_last_purchase_unix: int, p_now_unix: int) -> int:
	if(IsFavorAvailable(p_last_purchase_unix, p_now_unix)):
		return 0
	return GameBalance.SHOP_FORTUNES_FAVOR_COOLDOWN_SECONDS - (p_now_unix - p_last_purchase_unix)

static func GetGearPrice(p_rarity: Types.Rarity, p_item_type: Types.Item_Type = Types.Item_Type.Standard) -> int:
	var price: int = int(LootManager.GetSellValue(p_rarity) * GameBalance.SHOP_BUY_MARKUP)
	if(Types.Item_Type.Relic == p_item_type):
		return int(price * GameBalance.SHOP_RELIC_MARKUP_MULTIPLIER)
	return price

static func GetReagentPrice(p_rarity: Types.Rarity) -> int:
	return int(LootManager.GetReagentSellValue(p_rarity) * GameBalance.SHOP_BUY_MARKUP)

static func RollStock(p_budget: int) -> Array[Dictionary]:
	var stock: Array[Dictionary] = []

	for i in GameBalance.SHOP_GEAR_SLOTS:
		var best_rarity: int = LootManager.GetBestRarityForItem(p_budget)
		var rarity: Types.Rarity = LootManager.RollRarityForItem(best_rarity)
		var item_type: Types.Item_Type = LootManager.RollItemType()
		var preset_key: String = (
				EquipmentPresetRegistry.GetRandomRelicKey() if Types.Item_Type.Relic == item_type
				else EquipmentPresetRegistry.GetRandomKey())
		var base_preset: EquipmentPreset = (
				EquipmentPresetRegistry.GetRelic(preset_key) if Types.Item_Type.Relic == item_type
				else EquipmentPresetRegistry.Get(preset_key))
		var preset: EquipmentPreset = base_preset.duplicate(true)
		preset._rarity = rarity
		preset.Setup()
		stock.append({
			"category": Types.Category.Gear,
			"rarity": rarity,
			"item_type": item_type,
			"price": GetGearPrice(rarity, item_type),
			"sold_out": false,
			"payload": preset_key,
			"amount": 1,
			"attributes": _AttributesToStock(preset._attributes),
		})

	var reagent_best_rarity: int = LootManager.GetBestRarityForReagent(p_budget)
	var reagent_rarity: Types.Rarity = LootManager.RollRarityForReagent(reagent_best_rarity, Types.Rarity.Legendary)
	stock.append({
		"category": Types.Category.Reagent,
		"rarity": reagent_rarity,
		"price": GetReagentPrice(reagent_rarity),
		"sold_out": false,
		"payload": ReagentRegistry.GetRandomKeyForRarity(reagent_rarity),
		"amount": 1,
		"attributes": {},
	})

	stock.append({
		"category": Types.Category.Supplies,
		"rarity": 0,
		"price": GameBalance.SHOP_SUPPLIES_PRICE,
		"sold_out": false,
		"payload": "",
		"amount": GameBalance.SHOP_SUPPLIES_BUNDLE_AMOUNT,
		"attributes": {},
	})

	stock.append({
		"category": Types.Category.FortunesFavor,
		"rarity": FortuneFavorTier.TierType.BONE,
		"price": GameBalance.SHOP_FORTUNES_FAVOR_PRICE,
		"sold_out": false,
		"payload": "",
		"amount": 1,
		"attributes": {},
	})

	return stock

static func _AttributesToStock(p_attributes: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for attribute in p_attributes.keys():
		if(0 < p_attributes[attribute]):
			result[Types.Attribute.keys()[attribute]] = int(p_attributes[attribute])
	return result

func EnsureFresh() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	if(not IsRestockDue(_restock_anchor_unix, now)):
		return
	var budget: int = LootManager.CalculateBudget(main.GetInstance()._progress.GetHighestDifficulty())
	_stock = RollStock(budget)
	_restock_anchor_unix = now
	stock_changed.emit()

func Purchase(p_slot_index: int) -> bool:
	var entry: Dictionary = _stock[p_slot_index]
	if(entry["sold_out"]):
		return false

	var now: int = int(Time.get_unix_time_from_system())
	var is_favor: bool = entry["category"] == Types.Category.FortunesFavor
	if(is_favor and not IsFavorAvailable(_favor_purchase_unix, now)):
		return false

	if(not main.GetInstance()._resources.SpendSilver(entry["price"])):
		return false

	_grant(entry)
	entry["sold_out"] = true
	if(is_favor):
		_favor_purchase_unix = now
	return true

func Serialize() -> Dictionary:
	return {
		"stock": _stock.duplicate(true),
		"restock_anchor_unix": _restock_anchor_unix,
		"favor_purchase_unix": _favor_purchase_unix,
	}

func Deserialize(p_data: Dictionary) -> void:
	if(not p_data.has("stock")):
		print("No shop stock found in save slot.")
		return

	_stock.clear()
	for entry in p_data["stock"]:
		var attributes: Dictionary = {}
		for attribute_name in entry.get("attributes", {}).keys():
			attributes[attribute_name] = int(entry["attributes"][attribute_name])
		_stock.append({
			"category": int(entry["category"]),
			"rarity": int(entry["rarity"]),
			"item_type": int(entry.get("item_type", Types.Item_Type.Standard)),
			"price": int(entry["price"]),
			"sold_out": bool(entry["sold_out"]),
			"payload": String(entry["payload"]),
			"amount": int(entry["amount"]),
			"attributes": attributes,
		})
	_restock_anchor_unix = int(p_data.get("restock_anchor_unix", 0))
	_favor_purchase_unix = int(p_data.get("favor_purchase_unix", 0))

func _grant(p_entry: Dictionary) -> void:
	match p_entry["category"]:
		Types.Category.Gear:
			var item_type: Types.Item_Type = p_entry.get("item_type", Types.Item_Type.Standard) as Types.Item_Type
			var base_preset: EquipmentPreset = (
					EquipmentPresetRegistry.GetRelic(p_entry["payload"]) if Types.Item_Type.Relic == item_type
					else EquipmentPresetRegistry.Get(p_entry["payload"]))
			var preset: EquipmentPreset = base_preset.duplicate(true)
			preset._rarity = p_entry["rarity"]
			for attribute_name in p_entry["attributes"].keys():
				preset._attributes[Types.Attribute[attribute_name]] = p_entry["attributes"][attribute_name]
			main.GetInstance()._item_collection.AddPreset(preset)
		Types.Category.Reagent:
			main.GetInstance()._reagent_collection.Add(p_entry["payload"], p_entry["amount"])
		Types.Category.Supplies:
			main.GetInstance()._resources.AddSupplies(p_entry["amount"])
		Types.Category.FortunesFavor:
			main.GetInstance()._resources.AddFortunesFavor(FortuneFavorTier.TierType.BONE, p_entry["amount"])
