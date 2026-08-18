class_name ShieldWallTrait extends CharacterTrait

const REDIRECT_FRACTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.15,
	Types.Rarity.Rare: 0.20,
	Types.Rarity.Epic: 0.25,
	Types.Rarity.Legendary: 0.30,
}

const PROXIMITY_WINDOW: float = 0.15
const BRACE_FOR_IMPACT_SKILL_NAME: String = "Brace for Impact"
const ENFEEBLE_RIDER_KEY: StringName = &"attacker_debuff_on_damage"
const ENFEEBLE_DURATION: int = 2

var _redirect_fraction: float = 0.0

static func GetRedirectFraction(p_rarity: Types.Rarity) -> float:
	return REDIRECT_FRACTION.get(p_rarity, 0.0)

## The proximity window doesn't scale by rarity; this matches the
## PlanTrait/ForesightTrait GetReachThreshold shape so the turn bar can dispatch to
## it the same way.
static func GetReachThreshold(_p_rarity: Types.Rarity) -> float:
	return PROXIMITY_WINDOW

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_redirect_fraction = GetRedirectFraction(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/Shield_Wall_Trait/shield_wall_trait.png")
	_execution_steps[Types.Combat_Event.Ally_Damage_Taken] = Callable(self, "OnAllyDamageTaken")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_title = "Shield Wall"
	_body = "When an ally within 15% of the Warlord on the turn bar takes attack damage, " \
			+ str(_redirect_fraction * 100) + "% of it is redirected to the Warlord instead," \
			+ " mitigated by the Warlord's own Defence."

func OnAllyDamageTaken(
		p_owner_ID: int, p_damaged_ally_ID: int, p_resolver: BattleResolver) -> float:
	if(p_resolver.GetCharacters()[p_owner_ID]._current_health <= 0):
		return 0.0
	var nearby: Array[int] = p_resolver.GetTurnPositions().GetCharactersWithinProximity(
			p_owner_ID, PROXIMITY_WINDOW)
	if(not nearby.has(p_damaged_ally_ID)):
		return 0.0
	return _redirect_fraction

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	if(BRACE_FOR_IMPACT_SKILL_NAME == p_skill_name):
		result._trait_riders[ENFEEBLE_RIDER_KEY] = {
			&"type": Types.Debuff_Type.Enfeeble, &"duration": ENFEEBLE_DURATION}
	return result
