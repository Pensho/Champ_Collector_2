class_name CharacterTrait extends Resource


@warning_ignore_start("unused_private_class_variable")
var _execution_steps: Dictionary[Types.Combat_Event, Callable]
var _trait_texture: Texture2D
var _title: String = "Title"
var _body: String = "Body"
var _owner_rarity: Types.Rarity = Types.Rarity.Common
@warning_ignore_restore("unused_private_class_variable")

func Init(p_rarity: Types.Rarity) -> void:
	_owner_rarity = p_rarity

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

func StartOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func EndOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	return null

func OnSkillEffectsResolved(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> void:
	pass

func OnDefend(
		_p_defender_ID: int,
		_p_defender_attributes: Dictionary[Types.Attribute, int],
		_p_characters: Dictionary[int, Character]) -> void:
	pass

func BlocksForwardTurnBarBump(_p_owner_ID: int) -> bool:
	return false

func GetIncomingDebuffDurationBonus(_p_owner_ID: int) -> int:
	return 0

## Extra turns this owner's own applied debuffs last (e.g. the Herald of the Loom's
## Silver Thread), added alongside GetIncomingDebuffDurationBonus rather than in place
## of it.
func GetOutgoingDebuffDurationBonus(_p_owner_ID: int) -> int:
	return 0

## Whether this owner's own applied debuffs bypass the target's resist roll entirely.
func DebuffsCannotBeResisted(_p_owner_ID: int) -> bool:
	return false

## Returns the multiplier applied to incoming damage (1.0 = unchanged, 0.0 = avoided).
func OnDamageTaken(_p_owner_ID: int, _p_attacker_ID: int, _p_resolver: BattleResolver) -> float:
	return 1.0

func GetIncomingSingleTargetRedirectChance(_p_owner_ID: int) -> float:
	return 0.0

func OnDeath() -> void:
	pass

## Multiplier applied to this owner's whole enemy-AI targeting priority score
## (Health + Defence), not just its Defence component — a value above 1.0 makes
## the owner more likely to be chosen as a target, below 1.0 less likely.
func GetTargetingPriorityMultiplier() -> float:
	return 1.0

## Permanent multiplier this owner's trait applies to healing it receives
## (1.0 = unchanged). Composes with, but is separate from, expiring
## IncomingHealReduction debuffs.
func GetIncomingHealMultiplier(_p_owner_ID: int) -> float:
	return 1.0

## Permanent multiplier this owner's trait applies to healing and Barrier absorption it
## creates (1.0 = unchanged), read at the skill-effect layer (HealthChangeEffect's heal
## branch, BarrierEffect) rather than the resolver's generic heal path.
func GetOutgoingRestorationMultiplier(_p_owner_ID: int, _p_resolver: BattleResolver) -> float:
	return 1.0

func OnReagentConsumed(
		_p_consumer_ID: int, _p_reagent: ReagentData, _p_resolver: BattleResolver) -> float:
	return 0.0

func OnCriticalHit(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func OnDamageDealt(
		_p_owner_ID: int, _p_target_ID: int, _p_amount: int, _p_resolver: BattleResolver) -> void:
	pass

func OnAllyDeath(_p_owner_ID: int, _p_dead_ally_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func OnAllyReagentConsumed(
		_p_owner_ID: int, _p_consumer_ID: int, _p_reagent: ReagentData, _p_resolver: BattleResolver) -> void:
	pass

func OnKill(_p_owner_ID: int, _p_victim_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
	return 0.0

## Fraction of this owner's own attacks that bypasses the target's Defence, subtracted in
## points from a debuff-free reference Defence (Between the Plates). 0.0 = no bypass.
func GetBaseDefenceIgnoreRate(_p_owner_ID: int) -> float:
	return 0.0

## Returns the fraction of an ally's incoming attack damage this owner redirects to
## itself (0.0 = no redirect).
func OnAllyDamageTaken(
		_p_owner_ID: int, _p_damaged_ally_ID: int, _p_resolver: BattleResolver) -> float:
	return 0.0

func BrewReagentKey(_p_random: RandomNumberGenerator) -> String:
	return ""

func GetBrewPotencyBonus() -> float:
	return 0.0

func OnBuffGained(
		_p_owner_ID: int, _p_buff: StatusEffects.Buff, _p_resolver: BattleResolver) -> void:
	pass

func OnDebuffReceived(
		_p_owner_ID: int, _p_debuff: StatusEffects.Debuff, _p_resolver: BattleResolver) -> void:
	pass

func OnDebuffApplied(
		_p_owner_ID: int,
		_p_target_ID: int,
		_p_debuff: StatusEffects.Debuff,
		_p_resolver: BattleResolver) -> void:
	pass

## Returns the fraction of turn bar the owner tithes for itself when its own effect
## reduced an enemy's turn bar by p_reduction (0.0 = no tithe).
func OnEnemyTurnBarReduced(
		_p_owner_ID: int, _p_reduction: float, _p_resolver: BattleResolver) -> float:
	return 0.0

func OnZoneUsed(_p_owner_ID: int, _p_user_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func OnAllyTurnBarIncreased(
		_p_owner_ID: int, _p_target_ID: int, _p_fraction: float, _p_resolver: BattleResolver) -> void:
	pass

## Fires once per real cascade instance (one loop iteration of a matched
## CascadeResolver listener), for every living character, regardless of whose
## mechanic actually produced it — lets a passive react to instance count itself
## (e.g. the Herald of the Loom's Golden Thread).
func OnCascadeInstanceResolved(
		_p_owner_ID: int, _p_event: CascadeEvent, _p_resolver: BattleResolver) -> void:
	pass

func OnZoneConstructed(_p_owner_ID: int, _p_zone_ID: int, _p_resolver: BattleResolver) -> void:
	pass

## Returns a scalar bonus (e.g. Calibration's charge investment) folded into the size
## of the owner's own zone effect (0.0 = no bonus).
func GetZoneChargeBonus(_p_zone_ID: int) -> float:
	return 0.0

func GetCritChanceOverflowRate() -> float:
	return 0.0

func OnAffectedByZone(_p_owner_ID: int, _p_zone_owner_ID: int, _p_resolver: BattleResolver) -> void:
	pass

func GetIncomingZoneEffectMultiplier(
		_p_owner_ID: int, _p_zone_owner_ID: int, _p_sides: CombatSides) -> float:
	return 1.0

func GetAttributeDelta(_p_attribute: Types.Attribute, _p_base_value: int) -> int:
	return 0

## Lets this owner's trait set the value of a debuff it is about to apply (e.g. the
## Emissary's Infraction-scaled Sanction). A negative return (the default) means the
## trait has no opinion and the normal snapshot/template value is used.
func GetAppliedStatusValue(
		_p_owner_ID: int, _p_target_ID: int, _p_debuff_type: Types.Debuff_Type, _p_resolver: BattleResolver) -> float:
	return -1.0

## Answers a DamageEffect's bonus_per count, or a SkillEffect's condition test, for one
## Trait_Count_Source. The base class has none of them.
func GetConditionCount(
		_p_owner_ID: int,
		_p_target_ID: int,
		_p_source: Types.Trait_Count_Source,
		_p_resolver: BattleResolver) -> float:
	return 0.0
