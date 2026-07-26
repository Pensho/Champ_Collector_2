class_name OnTheHouseTrait extends CharacterTrait

const HEAL_FRACTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.06,
	Types.Rarity.Rare: 0.07,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.09,
}

var _heal_fraction: float = 0.0
var _round_poured_this_cycle: bool = false

static func GetHealFraction(p_rarity: Types.Rarity) -> float:
	return HEAL_FRACTION.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_heal_fraction = GetHealFraction(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/On_The_House_Trait/On_The_House_Trait.png")
	_execution_steps[Types.Combat_Event.Buff_Applied] = Callable(self, "OnBuffGained")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

	_title = "On the House!"
	_body = "Whenever the Bar Brawler gains a buff, all living player characters" \
			+ " heal " + str(_heal_fraction * 100) + "% of their own max" \
			+ " Health. This can happen at most once between his turns."

func StartOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_round_poured_this_cycle = false

func OnBuffGained(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	if(_round_poured_this_cycle or _heal_fraction <= 0.0):
		return
	_round_poured_this_cycle = true
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(
			p_resolver.GetCharacters())
	p_resolver.ResolveTraitHeal(allies, _heal_fraction)
	p_resolver.EmitTraitText(p_owner_ID, "On the House!", Color(0.9, 0.7, 0.1, 1.0))
