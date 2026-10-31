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
const BRACE_DAMAGE_REDUCTION: float = 0.5

var _redirect_fraction: float = 0.0

static func GetRedirectFraction(p_rarity: Types.Rarity) -> float:
	return REDIRECT_FRACTION.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_redirect_fraction = GetRedirectFraction(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/Shield_Wall_Trait/shield_wall_trait.png")
	# Placeholder until Shield Wall has its own turn bar art.
	_turn_bar_reach = TurnBarReach.new(PROXIMITY_WINDOW, load(
			"res://Assets/Champ_Collector/Icons/Abilities/Passives/Shield_Wall_Trait/shield_wall_turnbar_texture.jpg"),
			TurnBarReach.DEFAULT_OPACITY, true)
	_execution_steps[Types.Combat_Event.Other_Ally_Damage_Taken] = Callable(self, "OnOtherAllyDamageTaken")
	_execution_steps[Types.Combat_Event.Other_Ally_Debuff_Landed] = Callable(self, "TakesOtherAllyDebuffTurn")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_title = "Shield Wall"
	_body = ("Allies within 15%% on the turn bar pass %d%% of attack damage and 1 turn of enemy debuffs " %
				roundi(_redirect_fraction * 100.0) +
			"to the Warlord, keeping at least 1 turn.")

func OnOtherAllyDamageTaken(
		p_owner_ID: int, p_damaged_ally_ID: int, p_resolver: BattleResolver) -> float:
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]
	if(owner._current_health <= 0):
		return 0.0
	if(owner._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return b.trait_riders.has(
			StatusEffectResolver.DAMAGE_REDUCTION_RIDER_KEY))):
		return 1.0
	return _redirect_fraction if _IsInRange(p_owner_ID, p_damaged_ally_ID, p_resolver) else 0.0

func TakesOtherAllyDebuffTurn(p_owner_ID: int, p_ally_ID: int, p_resolver: BattleResolver) -> bool:
	return (p_resolver.GetCharacters()[p_owner_ID]._current_health > 0
			and _IsInRange(p_owner_ID, p_ally_ID, p_resolver))

func _IsInRange(p_owner_ID: int, p_ally_ID: int, p_resolver: BattleResolver) -> bool:
	return p_resolver.GetTurnPositions().GetCharactersWithinProximity(
			p_owner_ID, PROXIMITY_WINDOW).has(p_ally_ID)

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
		result._trait_riders[StatusEffectResolver.DAMAGE_REDUCTION_RIDER_KEY] = BRACE_DAMAGE_REDUCTION
	return result
