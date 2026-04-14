class_name PlanTrait extends CharacterTrait

var _trait_texture: Texture2D
var _title: String = "Title"
var _body: String = "Body"
var _start_of_turn_effects: TraitStartTurn

func Init() -> void:
	_trait_texture = load("uid://u2rpxcarwct2")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	
	_start_of_turn_effects = TraitStartTurn.new()
	_start_of_turn_effects.buffs[Types.Skill_Target.All_Other_Allies] = StatusEffects.Buff.new()
	_start_of_turn_effects.buffs[Types.Skill_Target.All_Other_Allies].type = Types.Buff_Type.Empower
	_start_of_turn_effects.buffs[Types.Skill_Target.All_Other_Allies].duration = 1
	_start_of_turn_effects.buffs[Types.Skill_Target.All_Other_Allies].name = "Empower"
	_start_of_turn_effects.buffs[Types.Skill_Target.All_Other_Allies].stackable = false
	
	_title = "Plan ahead"
	_body = "Casts Empower on each ally close enough at start of turn."

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

func StartOfTurn(
		p_owner_ID: int,
		p_battle_UI: BattleUI,
		p_characters: Dictionary[int, Character],
		p_character_repr: Array[CharacterRepresentation]) -> void:
	var characters_in_range = p_battle_UI._turn_bar.GetCharactersWithinRange(p_owner_ID, 0.7)
	if (characters_in_range.is_empty()):
		return
	
	var skill_targets: Array[int] = Skills.FindSkillTargets(p_owner_ID, p_owner_ID, Types.Skill_Target.All_Other_Allies)
	if (skill_targets.is_empty()):
		return
	
	for id in characters_in_range:
		if (skill_targets.has(id)):
			Skills.ApplyBuff(
					p_characters[id],
					_start_of_turn_effects.buffs[Types.Skill_Target.All_Other_Allies],
					p_character_repr[id],
					p_battle_UI)
