class_name PrismOfSmallFavorsRelic extends RelicEffect

const CRIT_CHANCE_PER_BUFF: int = 12
const HELD_BUFF_PENALTY: float = 0.50

var _owner_ID: int = -1
var _resolver: BattleResolver = null

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Prism_of_Small_Favors/Prism_of_Small_Favors.png")
	_title = "Prism of Small Favors"
	_magnitude_by_rarity = [2.0, 2.0, 3.0, 3.0, 4.0]
	_body = ("Each buff the wearer holds, up to " + str(roundi(Magnitude())) +
			" of them, grants +12% points Critical Chance.\n" +
			"Buffs the wearer holds have half their effect.")
	_execution_steps[Types.Combat_Event.Buff_Applied] = Callable(self, "OnBuffGained")

func ResetForBattle() -> void:
	_owner_ID = -1
	_resolver = null

func OnBuffGained(p_owner_ID: int, _p_buff: StatusEffects.Buff, p_resolver: BattleResolver) -> void:
	_owner_ID = p_owner_ID
	_resolver = p_resolver

func GetAttributeDelta(p_attribute: Types.Attribute, _p_base_value: int) -> int:
	if(Types.Attribute.CritChance != p_attribute or -1 == _owner_ID):
		return 0
	var owner: Character = _resolver.GetCharacters().get(_owner_ID)
	if(null == owner):
		return 0
	var counted_buffs: int = mini(owner._active_buffs.size(), int(Magnitude()))
	return counted_buffs * CRIT_CHANCE_PER_BUFF

func GetAppliedBuffValue(
		p_owner_ID: int, p_target_ID: int, p_buff_type: Types.Buff_Type, p_resolver: BattleResolver) -> float:
	if(p_owner_ID != p_target_ID):
		return -1.0
	var data: StatusEffectData = StatusEffectRegistry.BuffData(p_buff_type)
	if(null == data):
		return -1.0
	var base_value: float = p_resolver.GetStatusResolver().SnapshotStatusValue(data, p_owner_ID, p_target_ID)
	return base_value * HELD_BUFF_PENALTY
