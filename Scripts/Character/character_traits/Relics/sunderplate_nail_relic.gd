class_name SunderplateNailRelic extends RelicEffect

const HEALTH_COST_FRACTION: float = 0.10

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Sunderplate_Nail/Sunderplate_Nail.png")
	_title = "Sunderplate Nail"
	_magnitude_by_rarity = [0.18, 0.20, 0.23, 0.27, 0.32]
	_body = ("The wearer's damaging skills treat the target's Defence as " +
			str(roundi(Magnitude() * 100)) + "% lower.\n" +
			"The wearer loses 10% of their max Health whenever " +
			"they gain a buff.")
	_execution_steps[Types.Combat_Event.Buff_Applied] = Callable(self, "OnBuffGained")

func GetOutgoingDefenceIgnoreFactor(
		_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
	return 1.0 - Magnitude()

func OnBuffGained(p_owner_ID: int, _p_buff: StatusEffects.Buff, p_resolver: BattleResolver) -> void:
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]
	var cost: int = roundi(p_resolver.GetMaxHealth(p_owner_ID) * HEALTH_COST_FRACTION)
	p_resolver.SetCurrentHealth(p_owner_ID, owner._current_health - cost)
