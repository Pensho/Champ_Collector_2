class_name TheOssuaryLedgerRelic extends RelicEffect

var _triggered: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Ossuary_Ledger/The_Ossuary_Ledger.png")
	_title = "The Ossuary Ledger"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("When an ally dies, the wearer deals +" + str(roundi(Magnitude() * 100)) +
			"% damage for the rest of the battle.\n" +
			"The wearer can never gain a buff, from any source.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Ally_Death] = Callable(self, "OnAllyDeath")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_triggered = false
	var severance: StatusEffects.Debuff = StatusEffects.Debuff.new()
	severance.type = Types.Debuff_Type.Severance
	severance.duration = GameBalance.BATTLE_PERMANENT_EFFECT
	severance.name = "Severance"
	severance.source_ID = p_owner_ID
	p_resolver.GetStatusResolver().ApplyDebuff(p_owner_ID, severance)

func OnAllyDeath(_p_owner_ID: int, _p_dead_ally_ID: int, _p_resolver: BattleResolver) -> void:
	_triggered = true

func GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
	return Magnitude() if _triggered else 0.0
