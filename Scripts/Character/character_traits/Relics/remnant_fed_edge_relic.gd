class_name RemnantFedEdgeRelic extends RelicEffect

const OWN_REAGENT_PENALTY: float = -0.40

var _pending_bonus: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Remnant_Fed_Edge/Remnant_Fed_Edge.png")
	_title = "Remnant-Fed Edge"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("The first damaging skill cast after consuming a reagent deals +" +
			str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Reagents the wearer consumes have 40% less effect.")
	_execution_steps[Types.Combat_Event.Reagent_Consumed] = Callable(self, "OnReagentConsumed")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

func ResetForBattle() -> void:
	_pending_bonus = false

func OnReagentConsumed(
		_p_consumer_ID: int, _p_reagent: ReagentData, _p_resolver: BattleResolver) -> float:
	_pending_bonus = true
	return OWN_REAGENT_PENALTY

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	if(not _pending_bonus or not _DealsDamage(p_owner_ID, p_skill_name, p_resolver)):
		return result
	result._damage_multiplier = 1.0 + Magnitude()
	_pending_bonus = false
	return result

func _DealsDamage(p_owner_ID: int, p_skill_name: String, p_resolver: BattleResolver) -> bool:
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	if(not characters.has(p_owner_ID)):
		return false
	for cast_skill: Skill in characters[p_owner_ID]._skills:
		if(p_skill_name != cast_skill.name):
			continue
		for effect in cast_skill.effects:
			if(effect is DamageEffect):
				return true
		return false
	return false
