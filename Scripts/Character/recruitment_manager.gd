class_name RecruitmentManager extends Node

enum RewardType
{
	CHAMPION,
	SILVER,
	SUPPLIES,
}

const CHAMPION_CHANCE_PER_REWARD: float = 0.20
const PITY_THRESHOLD: int = 6
const PITY_BONUS_PER_PULL: float = 0.10

static func RollFiller(p_silver_weight: int, p_supplies_weight: int) -> RewardType:
	var total_weight: int = p_silver_weight + p_supplies_weight
	var roll: int = randi_range(1, total_weight)
	if(roll <= p_silver_weight):
		return RewardType.SILVER
	return RewardType.SUPPLIES

static func PityBonus(p_duplicate_count: int) -> float:
	if(p_duplicate_count < PITY_THRESHOLD):
		return 0.0
	return clampf((p_duplicate_count - PITY_THRESHOLD + 1) * PITY_BONUS_PER_PULL, 0.0, 1.0)

static func UnownedPresets(
		p_presets: Array[CharacterPreset], p_owned_names: Dictionary) -> Array[CharacterPreset]:
	var unowned: Array[CharacterPreset] = []
	for preset in p_presets:
		if(not p_owned_names.has(preset._name)):
			unowned.append(preset)
	return unowned

static func GroupByRarity(p_presets: Array[CharacterPreset]) -> Dictionary[Types.Rarity, Array]:
	var grouped: Dictionary[Types.Rarity, Array] = {}
	for preset in p_presets:
		if(not grouped.has(preset._rarity)):
			grouped[preset._rarity] = []
		grouped[preset._rarity].append(preset)
	return grouped

static func PickChampionByRarity(
		p_grouped: Dictionary[Types.Rarity, Array],
		p_rarity_weights: Dictionary[Types.Rarity, int]) -> CharacterPreset:
	var cumulative_weights: Dictionary[Types.Rarity, int] = {}
	var current_sum: int = 0
	for rarity in p_rarity_weights.keys():
		if(not p_grouped.has(rarity)):
			continue
		current_sum += p_rarity_weights[rarity]
		cumulative_weights[rarity] = current_sum
	var total_weight: int = current_sum

	var roll: int = randi_range(1, total_weight)
	var chosen_rarity: Types.Rarity = cumulative_weights.keys()[0]
	for rarity in cumulative_weights.keys():
		if(roll <= cumulative_weights[rarity]):
			chosen_rarity = rarity
			break

	var pool: Array = p_grouped[chosen_rarity]
	return pool[randi_range(0, pool.size() - 1)]

static func PickChampionWithPity(
		p_presets: Array[CharacterPreset],
		p_rarity_weights: Dictionary[Types.Rarity, int],
		p_owned_names: Dictionary,
		p_pity_bonus: float) -> CharacterPreset:
	var unowned: Array[CharacterPreset] = UnownedPresets(p_presets, p_owned_names)
	if(not unowned.is_empty() and randf() < p_pity_bonus):
		return PickChampionByRarity(GroupByRarity(unowned), p_rarity_weights)
	return PickChampionByRarity(GroupByRarity(p_presets), p_rarity_weights)

static func BuildRewards(
		p_tier: FortuneFavorTier,
		p_champion_gate: Array[bool],
		p_owned_names: Dictionary = {},
		p_pity_bonus: float = 0.0) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var champion_won: bool = false
	for i in p_tier.reward_count:
		if(not champion_won and p_champion_gate[i]):
			champion_won = true
			var champion: CharacterPreset = PickChampionWithPity(
					p_tier.recruitable_champions, LootManager.RARITY_WEIGHTING, p_owned_names, p_pity_bonus)
			rewards.append({"type": RewardType.CHAMPION, "champion": champion, "amount": 1})
		else:
			match RollFiller(p_tier.silver_weight, p_tier.supplies_weight):
				RewardType.SILVER:
					rewards.append({"type": RewardType.SILVER, "champion": null, "amount": p_tier.silver_amount})
				RewardType.SUPPLIES:
					rewards.append({"type": RewardType.SUPPLIES, "champion": null, "amount": p_tier.supplies_amount})
	return rewards

static func ResolveUse(p_tier: FortuneFavorTier) -> Array[Dictionary]:
	var champion_gate: Array[bool] = []
	for i in p_tier.reward_count:
		champion_gate.append(randf() < CHAMPION_CHANCE_PER_REWARD)

	var owned_names: Dictionary = main.GetInstance()._character_collection.GetOwnedChampionNames()
	var pity_bonus: float = PityBonus(main.GetInstance()._resources.GetFortunesFavorPity(p_tier.tier_type))

	var rewards: Array[Dictionary] = BuildRewards(p_tier, champion_gate, owned_names, pity_bonus)
	for reward in rewards:
		match reward["type"]:
			RewardType.CHAMPION:
				var champion: CharacterPreset = reward["champion"]
				if(owned_names.has(champion._name)):
					main.GetInstance()._resources.IncrementFortunesFavorPity(p_tier.tier_type)
				else:
					main.GetInstance()._resources.ResetFortunesFavorPity(p_tier.tier_type)
				main.GetInstance()._character_collection.Add(champion)
			RewardType.SILVER:
				main.GetInstance()._resources.AddSilver(reward["amount"])
			RewardType.SUPPLIES:
				main.GetInstance()._resources.AddSupplies(reward["amount"])
	return rewards
