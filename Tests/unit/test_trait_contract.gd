extends GutTest

# Every character-specific trait, graft and Relic is instantiated at every rarity and
# every hook declared on CharacterTrait is exercised once with an alive owner and once
# with a dead owner, so a new trait is covered by construction instead of needing its own
# bespoke test file. Also scans every script constant keyed by Types.Rarity and asserts
# it is no worse at Legendary than at Uncommon, and checks the ungated getter family for
# purity (see UNGATED_GETTERS below).

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const TRAIT_ROOT: String = "res://Scripts/Character/character_traits/CharacterSpecificTraits"
const GRAFT_ROOT: String = "res://Scripts/Character/character_traits/Grafts"
const RELIC_ROOT: String = "res://Scripts/Character/character_traits/Relics"

# CharacterTrait's Get*/Blocks*/Denies*/Suppresses*/DebuffsCannotBeResisted family: none
# may hold state. BrewReagentKey is excluded (RNG-driven by design).
const UNGATED_GETTERS: Array[String] = [
	"GetIncomingDebuffDurationBonus", "GetOutgoingDebuffDurationBonus", "DebuffsCannotBeResisted",
	"GetIncomingSingleTargetRedirectChance", "GetTargetingPriorityMultiplier", "GetIncomingHealMultiplier",
	"GetOutgoingRestorationMultiplier", "GetTeamReagentPotencyBonus", "SuppressesOwnCriticalHit",
	"GetOutgoingDamageBonus", "GetBaseDefenceIgnoreRate", "GetBrewPotencyBonus", "BlocksForwardTurnBarBump",
	"GetZoneChargeBonus", "GetCritChanceOverflowRate", "GetIncomingZoneEffectMultiplier", "GetAttributeDelta",
	"GetAppliedStatusValue", "GetAppliedBuffValue", "GetConditionCount", "GetAppliedAttributeAmplification",
	"GetOutgoingDefenceIgnoreFactor", "GetRewardMultiplier", "GetTeamCooldownlessDamagePenalty",
	"DeniesAlliesCriticalHits", "GetTeamBarrierMultiplier", "BlocksIncomingDebuffType",
]

const RARITIES: Array[Types.Rarity] = [
	Types.Rarity.Common,
	Types.Rarity.Uncommon,
	Types.Rarity.Rare,
	Types.Rarity.Epic,
	Types.Rarity.Legendary,
]

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_roster[3]._current_health = 0
	_sides = TestFactory.make_full_sides()
	_resolver = TestFactory.make_resolver(_roster, _sides)

func test_every_shipped_trait_and_graft_survives_init_at_every_rarity() -> void:
	var paths: Array[String] = _CollectScriptPaths()
	assert_gt(paths.size(), 0, "Sanity check: the trait/graft directory scan should find files")
	for path in paths:
		var script: GDScript = load(path)
		for rarity: Types.Rarity in RARITIES:
			var instance: CharacterTrait = script.new()
			instance.Init(rarity)
			assert_not_null(instance, "%s should instantiate at rarity %s" % [path, rarity])

func test_every_hook_is_callable_for_an_alive_and_a_dead_owner() -> void:
	var paths: Array[String] = _CollectScriptPaths()
	for path in paths:
		var script: GDScript = load(path)
		var instance: CharacterTrait = script.new()
		instance.Init(Types.Rarity.Legendary)
		_ExerciseHooks(instance, 0, 1, path)
		_ExerciseHooks(instance, 3, 1, path)

func test_rarity_scaling_tables_are_never_worse_at_legendary_than_uncommon() -> void:
	var paths: Array[String] = _CollectScriptPaths()
	var checked_any: bool = false
	for path in paths:
		var script: GDScript = load(path)
		var constants: Dictionary = script.get_script_constant_map()
		for constant_name in constants:
			var value = constants[constant_name]
			if not value is Dictionary:
				continue
			# Typed Dictionary.has() raises an engine error when probed with a key of the
			# wrong type (e.g. a String-keyed skill-name table), so match keys with '=='
			# instead of relying on has() to safely rule out non-Rarity-keyed constants.
			var uncommon_value = null
			var legendary_value = null
			for key in value.keys():
				if TYPE_INT != typeof(key):
					continue
				if key == Types.Rarity.Uncommon:
					uncommon_value = value[key]
				elif key == Types.Rarity.Legendary:
					legendary_value = value[key]
			if null != uncommon_value and null != legendary_value:
				checked_any = true
				assert_true(legendary_value >= uncommon_value,
						"%s.%s must not get worse at Legendary (%s) than at Uncommon (%s)" %
						[path, constant_name, legendary_value, uncommon_value])
	assert_true(checked_any, "Sanity check: at least one rarity-scaling table should be found")

func test_ungated_getters_are_pure_across_repeated_calls_with_identical_arguments() -> void:
	var paths: Array[String] = _CollectScriptPaths()
	for path in paths:
		var script: GDScript = load(path)
		var instance: CharacterTrait = script.new()
		instance.Init(Types.Rarity.Legendary)
		for getter_name in UNGATED_GETTERS:
			var args: Array = _GetterArgs(getter_name, 0, 1)
			var first: Variant = instance.callv(getter_name, args)
			var second: Variant = instance.callv(getter_name, args)
			assert_eq(first, second,
					"%s.%s must be pure (read-only, stateless): identical arguments answered differently" %
					[path, getter_name])

func _GetterArgs(p_getter_name: String, p_owner_ID: int, p_other_ID: int) -> Array:
	match p_getter_name:
		"GetIncomingDebuffDurationBonus", "GetOutgoingDebuffDurationBonus", \
				"GetIncomingSingleTargetRedirectChance", "GetIncomingHealMultiplier", \
				"GetBaseDefenceIgnoreRate", "BlocksForwardTurnBarBump":
			return [p_owner_ID]
		"DebuffsCannotBeResisted":
			return [p_owner_ID, p_other_ID]
		"GetTargetingPriorityMultiplier", "GetBrewPotencyBonus", "GetCritChanceOverflowRate", \
				"GetAppliedAttributeAmplification", "GetRewardMultiplier", \
				"GetTeamCooldownlessDamagePenalty", "DeniesAlliesCriticalHits", "GetTeamBarrierMultiplier":
			return []
		"GetOutgoingRestorationMultiplier", "GetTeamReagentPotencyBonus":
			return [p_owner_ID, _resolver]
		"SuppressesOwnCriticalHit":
			return [p_owner_ID, "Some Skill"]
		"GetOutgoingDamageBonus", "GetOutgoingDefenceIgnoreFactor":
			return [p_owner_ID, p_other_ID, _resolver]
		"GetZoneChargeBonus":
			return [0]
		"GetIncomingZoneEffectMultiplier":
			return [p_owner_ID, p_other_ID, _sides]
		"GetAttributeDelta":
			return [Types.Attribute.Health, 100]
		"GetAppliedStatusValue":
			return [p_owner_ID, p_other_ID, Types.Debuff_Type.Bleed, _resolver]
		"GetAppliedBuffValue":
			return [p_owner_ID, p_other_ID, Types.Buff_Type.Luck, _resolver]
		"GetConditionCount":
			return [p_owner_ID, p_other_ID, Types.Trait_Count_Source.Buffs_On_Caster, _resolver]
		"BlocksIncomingDebuffType":
			return [Types.Debuff_Type.Bleed]
		_:
			return []

func _ExerciseHooks(p_instance: CharacterTrait, p_owner_ID: int, p_other_ID: int, p_path: String) -> void:
	var caster_attributes: Dictionary[Types.Attribute, int] = _resolver.GetEffectiveAttributes(p_owner_ID)
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	var reagent: ReagentData = ReagentData.new()

	p_instance.StartOfBattle(p_owner_ID, _resolver)
	p_instance.StartOfTurn(p_owner_ID, _resolver)
	p_instance.EndOfTurn(p_owner_ID, _resolver)
	p_instance.OnSkillCast(p_owner_ID, [p_other_ID], "Strike", caster_attributes, _resolver)
	p_instance.OnDefend(p_owner_ID, caster_attributes, _resolver.GetCharacters())
	p_instance.BlocksForwardTurnBarBump(p_owner_ID)
	p_instance.GetIncomingDebuffDurationBonus(p_owner_ID)
	var damage_multiplier: float = p_instance.OnDamageTaken(p_owner_ID, p_other_ID, _resolver)
	assert_true(damage_multiplier >= 0.0, "%s OnDamageTaken must return a non-negative multiplier" % p_path)
	var redirect_chance: float = p_instance.GetIncomingSingleTargetRedirectChance(p_owner_ID)
	assert_true(redirect_chance >= 0.0 and redirect_chance <= 1.0,
			"%s GetIncomingSingleTargetRedirectChance must return a fraction" % p_path)
	p_instance.OnDeath()
	var targeting_multiplier: float = p_instance.GetTargetingPriorityMultiplier()
	assert_true(targeting_multiplier >= 0.0, "%s GetTargetingPriorityMultiplier must be non-negative" % p_path)
	var heal_multiplier: float = p_instance.GetIncomingHealMultiplier(p_owner_ID)
	assert_true(heal_multiplier >= 0.0, "%s GetIncomingHealMultiplier must be non-negative" % p_path)
	p_instance.OnReagentConsumed(p_owner_ID, reagent, _resolver)
	p_instance.GetTeamReagentPotencyBonus(p_owner_ID, _resolver)
	p_instance.OnCriticalHit(p_owner_ID, p_other_ID, _resolver)
	p_instance.SuppressesOwnCriticalHit(p_owner_ID, "Some Skill")
	p_instance.OnDamageDealt(p_owner_ID, p_other_ID, 10, _resolver)
	p_instance.OnAllyDeath(p_owner_ID, 3, _resolver)
	p_instance.OnAllyReagentConsumed(p_owner_ID, p_other_ID, reagent, _resolver)
	p_instance.OnKill(p_owner_ID, p_other_ID, _resolver)
	var outgoing_bonus: float = p_instance.GetOutgoingDamageBonus(p_owner_ID, p_other_ID, _resolver)
	assert_true(outgoing_bonus >= -1.0, "%s GetOutgoingDamageBonus must not imply negative damage" % p_path)
	var redirect_fraction: float = p_instance.OnAllyDamageTaken(p_owner_ID, p_other_ID, _resolver)
	assert_true(redirect_fraction >= 0.0 and redirect_fraction <= 1.0,
			"%s OnAllyDamageTaken must return a fraction" % p_path)
	p_instance.BrewReagentKey(RandomNumberGenerator.new())
	p_instance.GetBrewPotencyBonus()
	p_instance.OnBuffGained(p_owner_ID, buff, _resolver)
	p_instance.OnDebuffReceived(p_owner_ID, debuff, _resolver)
	p_instance.OnDebuffApplied(p_owner_ID, p_other_ID, debuff, _resolver)
	var tithe: float = p_instance.OnEnemyTurnBarReduced(p_owner_ID, 0.1, _resolver)
	assert_true(tithe >= 0.0 and tithe <= 1.0, "%s OnEnemyTurnBarReduced must return a fraction" % p_path)
	p_instance.OnZoneUsed(p_owner_ID, p_other_ID, 0, _resolver)
	p_instance.OnZoneConstructed(p_owner_ID, 0, _resolver)
	p_instance.GetZoneChargeBonus(0)
	p_instance.OnAffectedByZone(p_owner_ID, p_other_ID, _resolver)
	var zone_multiplier: float = p_instance.GetIncomingZoneEffectMultiplier(p_owner_ID, p_other_ID, _sides)
	assert_true(zone_multiplier >= 0.0, "%s GetIncomingZoneEffectMultiplier must be non-negative" % p_path)
	p_instance.GetAttributeDelta(Types.Attribute.Health, 100)
	var applied_status_value: float = p_instance.GetAppliedStatusValue(
			p_owner_ID, p_other_ID, Types.Debuff_Type.Bleed, _resolver)
	assert_true(applied_status_value >= -1.0,
			"%s GetAppliedStatusValue must return -1.0 (no opinion) or a real value" % p_path)
	var condition_count: float = p_instance.GetConditionCount(
			p_owner_ID, p_other_ID, Types.Trait_Count_Source.Buffs_On_Caster, _resolver)
	assert_true(condition_count >= 0.0, "%s GetConditionCount must be non-negative" % p_path)

func _CollectScriptPaths() -> Array[String]:
	var paths: Array[String] = []
	_CollectGDScriptPaths(TRAIT_ROOT, paths)
	_CollectGDScriptPaths(GRAFT_ROOT, paths)
	_CollectGDScriptPaths(RELIC_ROOT, paths)
	return paths

func _CollectGDScriptPaths(p_dir_path: String, p_out: Array[String]) -> void:
	var dir := DirAccess.open(p_dir_path)
	assert_not_null(dir, "Could not open directory: " + p_dir_path)
	if null == dir:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while "" != entry:
		if not entry.begins_with("."):
			var full_path: String = "%s/%s" % [p_dir_path, entry]
			if dir.current_is_dir():
				_CollectGDScriptPaths(full_path, p_out)
			elif entry.ends_with(".gd"):
				p_out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
