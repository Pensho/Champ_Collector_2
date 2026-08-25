class_name TheEvenTreadRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/The_Even_Tread/The_Even_Tread.png")
	_title = "The Even Tread"
	_magnitude_by_rarity = [0.50, 0.55, 0.60, 0.70, 0.85]
	_body = ("Buffs the wearer applies are +" + str(roundi(Magnitude() * 100)) +
			"% stronger.\n" +
			"The wearer's allies cannot critically hit.")

func GetAppliedBuffValue(
		p_owner_ID: int, p_target_ID: int, p_buff_type: Types.Buff_Type, p_resolver: BattleResolver) -> float:
	var data: StatusEffectData = StatusEffectRegistry.BuffData(p_buff_type)
	if(null == data):
		return -1.0
	var base_value: float = p_resolver.GetStatusResolver().SnapshotStatusValue(data, p_owner_ID, p_target_ID)
	return base_value * (1.0 + Magnitude())

func DeniesAlliesCriticalHits() -> bool:
	return true
