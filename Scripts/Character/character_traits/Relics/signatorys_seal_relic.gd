class_name SignatorysSealRelic extends RelicEffect

var _landed_count_by_target: Dictionary[int, int] = {}

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Signatorys_Seal/Signatorys_Seal.png")
	_title = "Signatory's Seal"
	_magnitude_by_rarity = [2.0, 2.0, 3.0, 3.0, 4.0]
	_body = ("The first " + str(roundi(Magnitude())) +
			" debuffs applied to each enemy in a battle cannot be resisted.\n" +
			"The wearer can never resist debuffs.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Debuff_Applied] = Callable(self, "OnDebuffApplied")

func ResetForBattle() -> void:
	_landed_count_by_target = {}

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var signed_writ: StatusEffects.Debuff = StatusEffects.Debuff.new()
	signed_writ.type = Types.Debuff_Type.Signed_Writ
	signed_writ.duration = GameBalance.BATTLE_PERMANENT_EFFECT
	signed_writ.name = "Signed Writ"
	signed_writ.source_ID = p_owner_ID
	p_resolver.GetStatusResolver().ApplyDebuff(p_owner_ID, signed_writ)

func DebuffsCannotBeResisted(_p_owner_ID: int, p_target_ID: int) -> bool:
	return _landed_count_by_target.get(p_target_ID, 0) < int(Magnitude())

func OnDebuffApplied(
		_p_owner_ID: int,
		p_target_ID: int,
		_p_debuff: StatusEffects.Debuff,
		_p_resolver: BattleResolver) -> void:
	_landed_count_by_target[p_target_ID] = _landed_count_by_target.get(p_target_ID, 0) + 1
