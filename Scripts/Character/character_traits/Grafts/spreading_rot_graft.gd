class_name SpreadingRotGraft extends GraftEffect

const HEALTH_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.12,
	Types.Rarity.Rare: 0.16,
	Types.Rarity.Epic: 0.20,
	Types.Rarity.Legendary: 0.24,
}

const BLIGHT_DURATION_PER_RARITY: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Uncommon: 1,
	Types.Rarity.Rare: 1,
	Types.Rarity.Epic: 2,
	Types.Rarity.Legendary: 2,
}

const SELF_ROT_FRACTION: float = 0.03

var _blight_debuff: StatusEffects.Debuff

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_title = "Spreading Rot"
	_body = ("Attacks apply Blight to their targets for " + str(BLIGHT_DURATION_PER_RARITY.get(p_rarity, 1))
			+ " turn(s). Gaining " + str(roundi(HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100)) + "% Health."
			+ " At the start of each of its turns, the Symbiote takes rot damage equal to 3% of its max Health.")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

	_blight_debuff = StatusEffects.Debuff.new()
	_blight_debuff.type = Types.Debuff_Type.Blight
	_blight_debuff.name = "Blight"
	_blight_debuff.duration = BLIGHT_DURATION_PER_RARITY.get(p_rarity, 1)

func OnSkillCast(
		p_owner_ID: int,
		p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	_blight_debuff.source_ID = p_owner_ID
	for target_ID in p_target_IDs:
		if p_resolver.GetSides().AreEnemies(p_owner_ID, target_ID):
			p_resolver.GetStatusResolver().ApplyDebuff(target_ID, _blight_debuff)
	return TraitSkillResult.new()

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]
	var rot_damage: int = int(SELF_ROT_FRACTION * p_resolver.GetMaxHealth(p_owner_ID))
	p_resolver.SetCurrentHealth(p_owner_ID, owner._current_health - rot_damage)

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Health: HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0)}
