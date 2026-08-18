class_name FreshBatchTrait extends CharacterTrait

const POTENCY_BONUS: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: -0.10,
	Types.Rarity.Rare: 0.0,
	Types.Rarity.Epic: 0.10,
	Types.Rarity.Legendary: 0.20,
}

const TEAM_DAMAGE_BONUS_ADDITION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.00,
	Types.Rarity.Rare: 0.03,
	Types.Rarity.Epic: 0.06,
	Types.Rarity.Legendary: 0.09,
}

const TEAM_DAMAGE_BUFF_DURATION: int = 2

const BASE_POOL: Array[String] = ["Lesser_Restorative_Brew", "Lesser_Tincture", "Lesser_Barrier_Brew"]
const PURGING_BREW: String = "Lesser_Purging_Brew"

var _potency_bonus: float = 0.0
var _team_damage_bonus: float = 0.0
var _team_damage_buff: StatusEffects.Buff

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_potency_bonus = POTENCY_BONUS.get(p_rarity, 0.0)
	var base_bonus: float = StatusEffectRegistry.BuffData(Types.Buff_Type.Volatile_Mixture).magnitude - 1.0
	_team_damage_bonus = base_bonus + TEAM_DAMAGE_BONUS_ADDITION.get(p_rarity, 0.0)
	_trait_texture = load(
			"res://Assets/Champ_Collector/Icons/Abilities/Passives/Fresh_Batch_Trait/fresh_batch_trait.png")
	_title = "Fresh Batch"
	_body = ("At the start of combat, brews one concoction drawn at random from the" \
			+ " Fresh Batch-exclusive brew pool.\n" \
			+ "Whenever any ally consumes a reagent, the whole" \
			+ " team gains a +%d%% damage buff for %d turns." \
					% [roundi(_team_damage_bonus * 100), TEAM_DAMAGE_BUFF_DURATION])

	_execution_steps[Types.Combat_Event.Ally_Reagent_Consumed] = Callable(self, "OnAllyReagentConsumed")

	_team_damage_buff = StatusEffects.Buff.new()
	_team_damage_buff.type = Types.Buff_Type.Volatile_Mixture
	_team_damage_buff.name = "Volatile Mixture"
	_team_damage_buff.duration = TEAM_DAMAGE_BUFF_DURATION
	_team_damage_buff.value = 1.0 + _team_damage_bonus

func BrewReagentKey(p_random: RandomNumberGenerator) -> String:
	var pool: Array[String] = BASE_POOL.duplicate()
	if(Types.Rarity.Epic == _owner_rarity or Types.Rarity.Legendary == _owner_rarity):
		pool.append(PURGING_BREW)
	return pool[p_random.randi_range(0, pool.size() - 1)]

func GetBrewPotencyBonus() -> float:
	return _potency_bonus

func OnAllyReagentConsumed(
		p_owner_ID: int, _p_consumer_ID: int, _p_reagent: ReagentData, p_resolver: BattleResolver) -> void:
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	for ally_ID in allies:
		p_resolver.GetStatusResolver().ApplyBuff(ally_ID, _team_damage_buff)
