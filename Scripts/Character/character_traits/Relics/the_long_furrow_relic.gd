class_name TheLongFurrowRelic extends RelicEffect

const CHARGE_SKILL_NAME: String = "Rending Charge"
const _CASCADE_MECHANIC_KEY: StringName = &"TheLongFurrowRelic"
const _MINIMUM_CHARGE_SPAN: int = 4

var _charge_span: int = 0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Long_Furrow/The_Long_Furrow.png")
	_title = "The Long Furrow"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.55]
	_body = ("Rending Charge Echoes once if the distance to the target is at least " + str(_MINIMUM_CHARGE_SPAN) + " or " +
			"more sections of turn-bar, at " + str(roundi(Magnitude() * 100)) + "% strength.\n" +
			"Rending Charge can never critically hit.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_charge_span = 0
	p_resolver.GetCascadeResolver().Subscribe(
			Types.Cascade_Trigger.Skill_Resolved,
			_CASCADE_MECHANIC_KEY,
			func(p_event: CascadeEvent) -> bool:
				return p_event.subject_ID == p_owner_ID and _charge_span >= _MINIMUM_CHARGE_SPAN,
			func(p_event: CascadeEvent) -> void: _EchoRendingCharge(p_owner_ID, p_event, p_resolver))

func OnSkillCast(
		p_owner_ID: int,
		p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	_charge_span = 0
	if(CHARGE_SKILL_NAME == p_skill_name and not p_target_IDs.is_empty()):
		var turn_positions: TurnPositions = p_resolver.GetTurnPositions()
		var owner_section: int = turn_positions.GetSectionIndex(p_owner_ID)
		var target_section: int = turn_positions.GetSectionIndex(p_target_IDs[0])
		if(owner_section >= 0 and target_section >= 0):
			var span: int = absi(owner_section - target_section) + 1
			if(_MINIMUM_CHARGE_SPAN <= span):
				_charge_span = span
	return TraitSkillResult.new()

func SuppressesOwnCriticalHit(_p_owner_ID: int, p_skill_name: String) -> bool:
	return CHARGE_SKILL_NAME == p_skill_name

func _EchoRendingCharge(p_owner_ID: int, p_event: CascadeEvent, p_resolver: BattleResolver) -> void:
	_charge_span = 0
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	if(not characters.has(p_owner_ID)):
		return
	var caster: Character = characters[p_owner_ID]
	if(p_event.skill_ID < 0 or p_event.skill_ID >= caster._skills.size()):
		return
	var cast_skill: Skill = caster._skills[p_event.skill_ID]
	var caster_attributes: Dictionary[Types.Attribute, int] = p_resolver.GetEffectiveAttributes(p_owner_ID)
	var context := SkillCastContext.new(p_resolver, p_owner_ID, p_event.target_IDs, cast_skill,
			caster_attributes, 0, TraitSkillResult.new())
	context.repeat_bonus = Magnitude() - 1.0
	for effect in cast_skill.effects:
		if(effect is DamageEffect and context.ConditionMet(effect)):
			effect.Resolve(context)
