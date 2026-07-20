class_name PilferTrait extends CharacterTrait

const STEAL_CHANCE: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.20,
	Types.Rarity.Rare: 0.30,
	Types.Rarity.Epic: 0.40,
	Types.Rarity.Legendary: 0.50,
}

var _steal_chance: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_steal_chance = STEAL_CHANCE.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
	_title = "Pilfer"
	_body = "Chance to steal a buff from the target when a skill is used."
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func OnSkillCast(
		p_owner_ID: int,
		p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()

	if (p_resolver.GetRandom().randf() >= _steal_chance):
		return result

	if (p_target_IDs.is_empty()):
		return result
	var target_ID: int = p_target_IDs[0]
	if (not characters.has(target_ID) or characters[target_ID]._current_health <= 0):
		return result

	var target_buffs: Array[StatusEffects.Buff] = characters[target_ID]._active_buffs
	if (target_buffs.is_empty()):
		return result

	var buff_to_steal: StatusEffects.Buff = target_buffs[
			p_resolver.GetRandom().randi() % target_buffs.size()]
	p_resolver.RemoveBuff(target_ID, buff_to_steal)
	p_resolver.ApplyBuff(p_owner_ID, buff_to_steal)
	p_resolver.EmitTraitText(p_owner_ID, "Stole buff!", Color(0.6, 0.2, 0.8, 1.0))

	return result
