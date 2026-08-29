class_name DropPreview extends RefCounted

static func Entries(p_loot_table: LootTable, p_difficulty: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if null == p_loot_table:
		return entries

	var budget: int = LootManager.CalculateBudget(p_difficulty)
	var seen: Dictionary[LootManager.LootType, bool] = {}
	for type in p_loot_table._primary_loot.keys():
		entries.append(_BuildEntry(type, true, p_loot_table, budget))
		seen[type] = true
	for type in p_loot_table._secondary_loot.keys():
		if seen.has(type):
			continue
		entries.append(_BuildEntry(type, false, p_loot_table, budget))
		seen[type] = true
	return entries

static func _BuildEntry(
		p_type: LootManager.LootType, p_guaranteed: bool, p_loot_table: LootTable, p_budget: int) -> Dictionary:
	return {
		"type": p_type,
		"guaranteed": p_guaranteed,
		"rarity": _BestRarity(p_type, p_loot_table, p_budget),
	}

static func _BestRarity(p_type: LootManager.LootType, p_loot_table: LootTable, p_budget: int) -> int:
	match p_type:
		LootManager.LootType.Equipment:
			return LootManager.GetBestRarityForItem(p_budget)
		LootManager.LootType.Reagent:
			return mini(LootManager.GetBestRarityForReagent(p_budget), p_loot_table._reagent_max_rarity as int)
		LootManager.LootType.Fortunes_Favor:
			return LootManager.GetBestFortuneFavorTier(p_budget)
		_:
			return -1

static func TypeLabel(p_type: LootManager.LootType) -> String:
	return LootManager.LootType.keys()[p_type].replace("_", " ")

static func BandLabel(p_entry: Dictionary) -> String:
	match p_entry["type"]:
		LootManager.LootType.Equipment, LootManager.LootType.Reagent:
			return Types.RarityName(p_entry["rarity"] as Types.Rarity)
		LootManager.LootType.Fortunes_Favor:
			return FortuneFavorTier.TierType.keys()[p_entry["rarity"]]
		_:
			return ""
