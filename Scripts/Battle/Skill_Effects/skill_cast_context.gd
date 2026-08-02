class_name SkillCastContext extends RefCounted

## Per-cast state threaded through a skill's effect loop: the read-only inputs every
## effect needs (resolver, caster, targets, the skill, caster attributes, use count,
## trait hook result), and the accumulators earlier effects write for later ones to
## read (health_paid, buffs_consumed). Replaces the growing parameter lists on
## _ResolveDamage/_ResolveStatusGroups and retires BuffManipulationResult.

var resolver: BattleResolver
var caster_ID: int
var target_IDs: Array[int]
var skill: Skill
var caster_attributes: Dictionary[Types.Attribute, int]
var use_count: int
var trait_result: TraitSkillResult

## Health the caster paid this cast.
var health_paid: int = 0
## Buffs consumed this cast, written by ConsumeBuffsEffect and read by a damage effect
## scaling off Buffs_Consumed.
var buffs_consumed: int = 0

func _init(
		p_resolver: BattleResolver,
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_use_count: int,
		p_trait_result: TraitSkillResult) -> void:
	resolver = p_resolver
	caster_ID = p_caster_ID
	target_IDs = p_target_IDs
	skill = p_skill
	caster_attributes = p_caster_attributes
	use_count = p_use_count
	trait_result = p_trait_result

## Resolves a target_type to caster-relative Character IDs, filtered to those alive:
## this cast's own targets when p_target_type is the skill's own target, otherwise
## resolved independently. The instance-friendly entry point for effects and other
## SkillCastContext holders; ResolveStatusGroupTargets is the same operation for
## resolvers that only have the raw caster/target/skill parameters, without a context.
func TargetsForGroup(p_target_type: Types.Skill_Target) -> Array[int]:
	return ResolveStatusGroupTargets(resolver, caster_ID, target_IDs, skill, p_target_type)

## Resolves an effect's own target group: Skill_Default reuses the skill's own targets
## (the p_target_IDs the skill was cast at), anything else resolves independently.
func TargetsFor(p_effect: SkillEffect) -> Array[int]:
	var effective_type: Types.Skill_Target = (
			skill.target if Types.Skill_Target.Skill_Default == p_effect.target else p_effect.target)
	return TargetsForGroup(effective_type)

## Whether p_effect's authored condition (if any) currently holds for this cast's
## primary target. A caster with no trait reads as a condition count of 0.0, so
## Condition_Test.Below is satisfiable (and At_Least never is) even without a trait.
func ConditionMet(p_effect: SkillEffect) -> bool:
	if(Types.Skill_Condition.None == p_effect.condition):
		return true
	var caster_trait: CharacterTrait = resolver.GetCharacters()[caster_ID]._trait
	var primary_target_ID: int = target_IDs[0] if not target_IDs.is_empty() else -1
	var source: Types.Damage_Bonus_Source = (
			Types.Damage_Bonus_Source.Trait_Condition if Types.Skill_Condition.Trait_Condition == p_effect.condition
			else Types.Damage_Bonus_Source.Trait_Counter_On_Target)
	var count: float = (caster_trait.GetConditionCount(caster_ID, primary_target_ID, source, resolver)
			if null != caster_trait else 0.0)
	if(Types.Condition_Test.At_Least == p_effect.condition_test):
		return count >= p_effect.condition_threshold
	return count < p_effect.condition_threshold

## Resolves one skill/effect target group to the caster-relative Character IDs it
## names, filtered to those alive: p_target_IDs when p_target_type is the skill's own
## target, otherwise resolved independently of the primary cast.
static func ResolveStatusGroupTargets(
		p_resolver: BattleResolver,
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_target_type: Types.Skill_Target) -> Array[int]:
	var group_IDs: Array[int] = (p_target_IDs if p_target_type == p_skill.target
			else ResolveIndependentGroup(p_resolver, p_caster_ID, p_target_type))
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	return group_IDs.filter(func(id): return characters.has(id) and characters[id]._current_health > 0)

static func ResolveIndependentGroup(
		p_resolver: BattleResolver, p_caster_ID: int, p_target_type: Types.Skill_Target) -> Array[int]:
	var sides: CombatSides = p_resolver.GetSides()
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var random: RandomNumberGenerator = p_resolver.GetRandom()
	var max_health: Callable = func(p_character: Character) -> int:
		return p_resolver.GetMaxHealth(p_character._instance_ID)
	var group_IDs: Array[int] = []
	match p_target_type:
		Types.Skill_Target.Self, Types.Skill_Target.Single_Ally:
			group_IDs = [p_caster_ID]
		Types.Skill_Target.All_Allies, Types.Skill_Target.All_Other_Allies, Types.Skill_Target.Ally_Not_Self:
			group_IDs = sides.AlliesOf(p_caster_ID).members.duplicate()
			if(Types.Skill_Target.All_Allies != p_target_type):
				group_IDs.erase(p_caster_ID)
		Types.Skill_Target.Random_Ally:
			group_IDs = Skills.SingleTargetArray(sides.AlliesOf(p_caster_ID).RandomAliveMember(characters, random))
		Types.Skill_Target.All_Enemies:
			group_IDs = sides.EnemiesOf(p_caster_ID).members
		Types.Skill_Target.Random_Enemy:
			group_IDs = Skills.SingleTargetArray(sides.EnemiesOf(p_caster_ID).RandomAliveMember(characters, random))
		Types.Skill_Target.Random_One:
			group_IDs = Skills.SingleTargetArray(sides.RandomAliveMember(characters, random))
		Types.Skill_Target.All:
			group_IDs = sides.AllMembers()
		Types.Skill_Target.Most_Injured_Ally:
			group_IDs = Skills.SingleTargetArray(
					Skills.MostInjured(sides.AlliesOf(p_caster_ID).members, characters, max_health))
		Types.Skill_Target.Most_Buffed_Ally:
			group_IDs = Skills.SingleTargetArray(Skills.MostBuffed(sides.AlliesOf(p_caster_ID).members, characters))
		_:
			print("Skill target enum has no caster-relative resolution for a secondary status group: ", p_target_type)
	return group_IDs
