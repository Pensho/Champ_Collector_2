class_name KilnBrandRelic extends RelicEffect

const DEBUFF_SKILL_PENALTY: float = 0.40

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/Relics/Kiln_Brand/Kiln_Brand.png")
	_title = "Kiln Brand"
	_magnitude_by_rarity = [0.20, 0.30, 0.40, 0.50, 0.65]
	_body = ("Skills that can go on cooldown deal +" + str(roundi(Magnitude() * 100)) +
			"% damage.\n" +
			"The wearer's damaging skills that can apply a debuff deal 40% less " +
			"damage.")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result := TraitSkillResult.new()
	var skill: Skill = _FindSkill(p_owner_ID, p_skill_name, p_resolver)
	if(null == skill):
		return result
	var multiplier: float = 1.0
	if(skill.cooldown > 0):
		multiplier += Magnitude()
	if(_CanApplyADebuff(skill)):
		multiplier -= DEBUFF_SKILL_PENALTY
	result._damage_multiplier = multiplier
	return result

func _FindSkill(p_owner_ID: int, p_skill_name: String, p_resolver: BattleResolver) -> Skill:
	for skill: Skill in p_resolver.GetCharacters()[p_owner_ID]._skills:
		if(skill.name == p_skill_name):
			return skill
	return null

func _CanApplyADebuff(p_skill: Skill) -> bool:
	var has_damage: bool = false
	var has_debuff: bool = false
	for effect in p_skill.effects:
		if(effect is DamageEffect):
			has_damage = true
		elif(effect is ApplyDebuffEffect):
			has_debuff = true
	return has_damage and has_debuff
