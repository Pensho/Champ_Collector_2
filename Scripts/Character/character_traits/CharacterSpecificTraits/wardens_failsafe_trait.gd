class_name WardensFailsafeTrait extends CharacterTrait

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Wardens_Failsafe/Wardens_Failsafe.png"
	)
	_execution_steps[Types.Combat_Event.Ally_Death] = Callable(self, "OnAllyDeath")

	_title = "Warden's Failsafe"
	_body = "When an ally dies, the user gains the Frenzy buff for the rest of the battle."

func RefreshVisuals(_p_character_repr: CharacterRepresentation) -> void:
	pass

func OnAllyDeath(p_owner_ID: int, _p_dead_ally_ID: int, p_resolver: BattleResolver) -> void:
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]
	for buff: StatusEffects.Buff in owner._active_buffs:
		if(Types.Buff_Type.Frenzy == buff.type):
			return
	var frenzy: StatusEffects.Buff = StatusEffects.Buff.new()
	frenzy.type = Types.Buff_Type.Frenzy
	frenzy.duration = GameBalance.BATTLE_PERMANENT_EFFECT
	frenzy.name = "Frenzy"
	p_resolver.GetStatusResolver().ApplyBuff(p_owner_ID, frenzy)
