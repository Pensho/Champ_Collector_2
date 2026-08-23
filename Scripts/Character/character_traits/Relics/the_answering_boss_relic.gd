class_name TheAnsweringBossRelic extends RelicEffect

const HEALTH_DRAWBACK: float = 0.30

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Answering_Boss/The_Answering_Boss.png")
	_title = "The Answering Boss"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("While the wearer holds a Barrier, damaging skills deal +" +
			str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"The wearer's max Health is reduced by 30%.")

func GetOutgoingDamageBonus(p_owner_ID: int, _p_target_ID: int, p_resolver: BattleResolver) -> float:
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]
	for buff: StatusEffects.Buff in owner._active_buffs:
		if(Types.Buff_Type.Barrier == buff.type):
			return Magnitude()
	return 0.0

func GetAttributeDelta(p_attribute: Types.Attribute, p_base_value: int) -> int:
	if(Types.Attribute.Health != p_attribute):
		return 0
	return -int(ceilf(p_base_value * HEALTH_DRAWBACK))
