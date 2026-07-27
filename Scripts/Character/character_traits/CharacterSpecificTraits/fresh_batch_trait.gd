class_name FreshBatchTrait extends CharacterTrait

const POTENCY_BONUS: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: -0.10,
	Types.Rarity.Rare: 0.0,
	Types.Rarity.Epic: 0.10,
	Types.Rarity.Legendary: 0.20,
}

const BASE_POOL: Array[String] = ["Lesser_Restorative_Brew", "Lesser_Tincture", "Lesser_Barrier_Brew"]
const PURGING_BREW: String = "Lesser_Purging_Brew"

var _potency_bonus: float = 0.0


func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_potency_bonus = POTENCY_BONUS.get(p_rarity, 0.0)
	_trait_texture = load(
			"res://Assets/Champ_Collector/Icons/Abilities/Passives/Fresh_Batch_Trait/fresh_batch_trait.png")
	_title = "Fresh Batch"
	_body = ("At the start of combat, brews one concoction drawn at random from the" \
			+ " Alchemist-exclusive brew pool, occupying its own reagent slot. It follows" \
			+ " normal reagent rules but is lost if unconsumed when the battle ends.")

func BrewReagentKey(p_random: RandomNumberGenerator) -> String:
	var pool: Array[String] = BASE_POOL.duplicate()
	if(Types.Rarity.Epic == _owner_rarity or Types.Rarity.Legendary == _owner_rarity):
		pool.append(PURGING_BREW)
	return pool[p_random.randi_range(0, pool.size() - 1)]

func GetBrewPotencyBonus() -> float:
	return _potency_bonus
