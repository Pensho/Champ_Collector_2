class_name PressTheAdvantageTrait extends CharacterTrait

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_execution_steps[Types.Combat_Event.Ally_Attack_Landed] = Callable(self, "OnAllyAttackLanded")

	_title = "Press the Advantage"
	_body = "Whenever an allied attack hits a Spotted enemy, this character gains one Momentum stack."

func OnAllyAttackLanded(
		p_owner_ID: int, _p_attacker_ID: int, p_target_ID: int, p_resolver: BattleResolver) -> void:
	var target: Character = p_resolver.GetCharacters().get(p_target_ID)
	if(null == target or not target._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Spotted == debuff.type)):
		return
	var momentum: StatusEffects.Buff = StatusEffects.Buff.new()
	momentum.type = Types.Buff_Type.Momentum
	momentum.name = "Momentum"
	momentum.source_ID = p_owner_ID
	p_resolver.GetStatusResolver().ApplyStackingBuff(p_owner_ID, momentum)

func RefreshVisuals(_p_character_repr: CharacterRepresentation) -> void:
	pass
