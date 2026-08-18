class_name LancerTrait extends CharacterTrait

const CHARGE_BONUS_PER_SECTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.09,
	Types.Rarity.Rare: 0.12,
	Types.Rarity.Epic: 0.15,
	Types.Rarity.Legendary: 0.18,
}

const RECOIL_PER_SECTION: float = 0.10
const CHARGE_SKILL_NAME: String = "Rending Charge"

var _bonus_per_section: float = 0.0
var _charge_span: int = 0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_bonus_per_section = CHARGE_BONUS_PER_SECTION.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/Lancer_Trait/lancer_trait.png")
	_title = "Couched Lance"
	_body = ("Rending Charge deals " + str(roundi(_bonus_per_section * 100)) + "% more damage per " +
			"turn-bar section between the Lancer and its target, then throws the Lancer back " +
			str(roundi(RECOIL_PER_SECTION * 100)) + "% of the turn bar per section charged.")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Skill_Effects_Resolved] = Callable(self, "OnSkillEffectsResolved")

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

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
			_charge_span = absi(owner_section - target_section) + 1
	return TraitSkillResult.new()

func OnSkillEffectsResolved(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> void:
	if(CHARGE_SKILL_NAME == p_skill_name and _charge_span > 0):
		p_resolver.BumpTurnBar(p_owner_ID, -RECOIL_PER_SECTION * _charge_span, p_owner_ID)
	_charge_span = 0

func GetConditionCount(
		_p_owner_ID: int,
		_p_target_ID: int,
		p_source: Types.Trait_Count_Source,
		_p_resolver: BattleResolver) -> float:
	if(Types.Trait_Count_Source.Turn_Bar_Section_Span == p_source):
		return float(_charge_span) * _bonus_per_section
	return 0.0
