class_name PilferTrait extends CharacterTrait

const STEAL_CHANCE: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.20,
	Types.Rarity.Rare: 0.30,
	Types.Rarity.Epic: 0.40,
	Types.Rarity.Legendary: 0.50,
}

func Init() -> void:
	_trait_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
	_title = "Pilfer"
	_body = "Chance to steal a buff from the target when a skill is used."
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

func OnSkillCast(
		p_owner_ID: int,
		p_target_IDs: Array[int],
		p_characters: Dictionary[int, Character],
		p_character_repr: Array[CharacterRepresentation],
		_p_skill_name: String,
		p_battle_ui: BattleUI,
		_p_caster_attributes: Dictionary[Types.Attribute, int]) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()

	var chance: float = STEAL_CHANCE.get(p_characters[p_owner_ID]._rarity, 0.0)
	if (randf() >= chance):
		return result

	if (p_target_IDs.is_empty()):
		return result
	var target_ID: int = p_target_IDs[0]
	if (not p_characters.has(target_ID) or p_characters[target_ID]._current_health <= 0):
		return result

	var target_buffs: Array[StatusEffects.Buff] = p_characters[target_ID]._active_buffs
	if (target_buffs.is_empty()):
		return result

	var buff_to_steal: StatusEffects.Buff = target_buffs[randi() % target_buffs.size()]
	Skills.RemoveBuff(p_characters[target_ID], buff_to_steal, p_character_repr[target_ID], p_battle_ui)
	Skills.ApplyBuff(p_characters[p_owner_ID], buff_to_steal, p_character_repr[p_owner_ID], p_battle_ui)
	p_battle_ui.SpawnCombatText("Stole buff!", p_character_repr[p_owner_ID].position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(0.6, 0.2, 0.8, 1.0))

	return result
