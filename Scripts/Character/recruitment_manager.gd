class_name RecruitmentManager extends Node

enum RewardType
{
	CHAMPION,
	SILVER,
	SUPPLIES,
}

const CHAMPION_CHANCE_PER_REWARD: float = 0.20

static func RollFiller(p_silver_weight: int, p_supplies_weight: int) -> RewardType:
	var total_weight: int = p_silver_weight + p_supplies_weight
	var roll: int = randi_range(1, total_weight)
	if(roll <= p_silver_weight):
		return RewardType.SILVER
	return RewardType.SUPPLIES

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

static func BuildRewards(p_tier: FortuneFavorTier, p_champion_gate: Array[bool]) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var champion_won: bool = false
	for i in p_tier.reward_count:
		if(not champion_won and p_champion_gate[i]):
			champion_won = true
			var grouped: Dictionary[Types.Rarity, Array] = GroupByRarity(p_tier.recruitable_champions)
			var champion: CharacterPreset = PickChampionByRarity(grouped, LootManager.RARITY_WEIGHTING)
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

	var rewards: Array[Dictionary] = BuildRewards(p_tier, champion_gate)
	for reward in rewards:
		match reward["type"]:
			RewardType.CHAMPION:
				main.GetInstance()._character_collection.Add(reward["champion"])
			RewardType.SILVER:
				main.GetInstance()._resources.AddSilver(reward["amount"])
			RewardType.SUPPLIES:
				main.GetInstance()._resources.AddSupplies(reward["amount"])
	return rewards
