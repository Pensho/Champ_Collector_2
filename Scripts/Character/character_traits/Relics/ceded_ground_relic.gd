class_name CededGroundRelic extends RelicEffect

const MYSTICISM_DRAWBACK: float = 0.50

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Ceded_Ground/Ceded_Ground.png")
	_title = "Ceded Ground"
	_magnitude_by_rarity = [0.08, 0.10, 0.12, 0.14, 0.17]
	_body = ("When an ally lands a critical hit while holding a buff the wearer applied, " +
			"that ally heals for " + str(roundi(Magnitude() * 100)) + "% of the damage " +
			"dealt.\n" +
			"The healing is paid out of the wearer's own Health, and the wearer's " +
			"Mysticism is reduced by 50%.")
	_execution_steps[Types.Combat_Event.Ally_Critical_Hit] = Callable(self, "OnAllyCriticalHit")

func OnAllyCriticalHit(
		p_owner_ID: int, p_ally_ID: int, _p_target_ID: int, p_amount: int, p_resolver: BattleResolver) -> void:
	var ally: Character = p_resolver.GetCharacters().get(p_ally_ID)
	if(null == ally):
		return
	var holds_wearers_buff: bool = false
	for buff: StatusEffects.Buff in ally._active_buffs:
		if(p_owner_ID == buff.source_ID):
			holds_wearers_buff = true
			break
	if(not holds_wearers_buff):
		return
	var heal_requested: int = int(floor(p_amount * Magnitude()))
	if(heal_requested <= 0):
		return
	var healed: int = p_resolver.ResolveHealthGain(p_ally_ID, heal_requested)
	if(healed > 0):
		p_resolver.ResolveHealthCost(p_owner_ID, healed)

func GetAttributeDelta(p_attribute: Types.Attribute, p_base_value: int) -> int:
	if(Types.Attribute.Mysticism != p_attribute):
		return 0
	return -int(ceilf(p_base_value * MYSTICISM_DRAWBACK))
