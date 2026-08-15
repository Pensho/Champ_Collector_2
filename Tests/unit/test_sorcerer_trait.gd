extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _trait: SorcererTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func before_each() -> void:
	_character = Character.new()
	_character._current_health = 10
	_character._attributes[Types.Attribute.Health] = 10
	_trait = SorcererTrait.new()
	_characters = {0: _character}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], []))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

# --- Stack accrual per skill cast ---

func test_skill_cast_increments_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 0}
	_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)
	assert_eq(_trait._instability_stacks, 1, "Casting any skill should add one Instability stack")

func test_stacks_capped_at_max_without_reagents() -> void:
	_InitTrait(Types.Rarity.Epic)
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 0}
	# Exactly MAX_INSTABILITY_STACKS casts reach the cap without yet triggering a Surge
	# (Surge fires on the next cast made *while already at* max stacks).
	for i in SorcererTrait.MAX_INSTABILITY_STACKS:
		_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)
	assert_eq(_trait._instability_stacks, SorcererTrait.MAX_INSTABILITY_STACKS,
		"Instability stacks must not exceed MAX_INSTABILITY_STACKS")

# --- Reagent consumption hook ---

func test_reagent_consumption_grants_two_stacks() -> void:
	_InitTrait(Types.Rarity.Rare)
	_trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_eq(_trait._instability_stacks, 2, "Consuming a reagent should grant two stacks")

func test_reagent_consumption_grants_an_echo_charge() -> void:
	_InitTrait(Types.Rarity.Rare)
	_trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_eq(_trait._echo_charges, 1, "Consuming a reagent should grant one Echo charge")

func test_reagent_consumption_capped_at_max() -> void:
	_InitTrait(Types.Rarity.Rare)
	_trait._instability_stacks = 4
	_trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_eq(_trait._instability_stacks, SorcererTrait.MAX_INSTABILITY_STACKS,
		"Reagent stacks must not exceed MAX_INSTABILITY_STACKS")

func test_reagent_consumption_returns_amplification_by_rarity() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var amplification: float = _trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_eq(amplification, 0.50)

# --- Surge ---

func test_surge_fires_only_at_max_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	var ally: Character = TestFactory.make_character()
	ally._current_health = 10
	ally._rarity = Types.Rarity.Epic
	_characters[1] = ally
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1], []))

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	# Reaching max stacks does not itself release a Surge — only the next cast made
	# while already at max stacks does.
	for i in SorcererTrait.MAX_INSTABILITY_STACKS:
		_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)
	assert_eq(_trait._instability_stacks, SorcererTrait.MAX_INSTABILITY_STACKS)
	assert_eq(ally._current_health, 10, "No Surge should fire on the cast that reaches max stacks")

	_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)
	assert_lt(ally._current_health, 10, "Surge should fire on the next cast made while at max stacks")

func test_surge_damages_allies_and_the_sorcerer() -> void:
	_InitTrait(Types.Rarity.Epic)
	var ally: Character = TestFactory.make_character()
	ally._current_health = 10
	ally._rarity = Types.Rarity.Epic
	_characters[1] = ally
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1], []))
	_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)

	assert_lt(ally._current_health, 10, "Surge should damage allies")
	assert_lt(_character._current_health, 10, "Surge should damage the Sorcerer themselves")

func test_surge_damages_enemies() -> void:
	_InitTrait(Types.Rarity.Epic)
	var enemy: Character = TestFactory.make_character()
	enemy._current_health = 10
	enemy._rarity = Types.Rarity.Epic
	_characters[1] = enemy
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))
	_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)

	assert_lt(enemy._current_health, 10, "Surge should damage enemies too")

func test_surge_never_crits() -> void:
	_InitTrait(Types.Rarity.Epic)
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000  # Health(1000) x ATTRIBUTE_HEALTH_MULTIPLIER(4)
	enemy._rarity = Types.Rarity.Epic
	_characters[1] = enemy
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))
	_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS

	# Guarantee a crit roll would succeed if it were possible (100 CritChance).
	var attributes: Dictionary[Types.Attribute, int] = {
		Types.Attribute.Mysticism: 100, Types.Attribute.CritChance: 100, Types.Attribute.CritDamage: 500}
	_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)

	var damage_taken: int = 4000 - enemy._current_health
	# A non-crit hit lands well under 300 here; a crit (CritDamage 500) would land
	# around 700+. Assert we stay under that boundary, i.e. no crit was rolled.
	assert_true(damage_taken > 0 and damage_taken < 300, "Surge must never roll a critical hit")

func test_surge_resets_stacks() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)

	assert_eq(_trait._instability_stacks, 0, "Surge should reset all stacks after release")

func test_surge_grants_an_echo_charge_not_consumed_by_the_triggering_cast() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS

	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Zap", attributes, _resolver)

	assert_eq(_trait._echo_charges, 1, "Releasing a Surge should grant one Echo charge")
	assert_eq(_trait._echoes_for_this_cast, 0,
		"The Surge's own Echo charge is banked for the NEXT cast, not consumed by this one")

# --- Battle start ---

func test_stacks_reset_at_battle_start() -> void:
	_trait._instability_stacks = 3
	_trait.StartOfBattle(0, _resolver)
	assert_eq(_trait._instability_stacks, 0, "Instability stacks should not persist between combats")

# --- Echo-triggered skill repeat ---

func _make_repeat_test_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Bolt"
	skill.target = Types.Skill_Target.Single_Enemy
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	var burn: ApplyDebuffEffect = ApplyDebuffEffect.new()
	burn.debuff_type = Types.Debuff_Type.Burning
	burn.duration = 2
	skill.effects = [damage, burn]
	return skill

func _make_zone_test_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Rift"
	skill.target = Types.Skill_Target.ZoneAll
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 0.5}
	var zone: ZoneEffect = ZoneEffect.new()
	zone.charges = 5
	zone.section = ZoneEffect.Section.Left_Most_Empty
	zone.on_trigger = [damage]
	skill.effects = [zone]
	return skill

## A caster with a Sorcerer trait and a damage+debuff skill, and a durable enemy target,
## with StartOfBattle already broadcast (so the trait's Skill_Resolved subscription is live).
func _make_repeat_test_setup() -> Dictionary:
	var caster: Character = TestFactory.make_character()
	caster._current_health = 10
	caster._rarity = Types.Rarity.Rare
	var caster_trait: SorcererTrait = SorcererTrait.new()
	caster_trait.Init(Types.Rarity.Rare)
	caster._trait = caster_trait
	caster._skills = [_make_repeat_test_skill()]
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000  # Health(1000) x ATTRIBUTE_HEALTH_MULTIPLIER(4)
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	return {"trait": caster_trait, "resolver": resolver, "enemy": enemy}

func _damage_results_against(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind and p_target_ID == r.target_ID)

func test_no_repeat_without_reagent_consumption() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var resolver: BattleResolver = setup["resolver"]
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	assert_eq(_damage_results_against(results, 1).size(), 1,
		"With no reagent consumed, a cast should deal damage once, not repeat")

func test_reagent_consumption_repeats_the_next_skill_once() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var damage_results: Array[CombatResult] = _damage_results_against(results, 1)
	assert_eq(damage_results.size(), 2,
		"A reagent consumed before casting should make the cast repeat exactly once")
	assert_lt(damage_results[1].amount, damage_results[0].amount,
		"The repeat should deal less damage than the original cast (REPEAT_FRACTION < 1.0)")
	assert_eq(damage_results[1].cascade_depth, 1, "The repeat is a depth-1 cascade instance")

func test_repeat_bucket_carries_the_repeat_fraction() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var damage_results: Array[CombatResult] = _damage_results_against(results, 1)
	var buckets: Dictionary[StringName, float] = damage_results[1].combined_damage_modifier.Buckets()
	var repeat_key: StringName = StringName("Bolt (repeat)")
	assert_true(buckets.has(repeat_key), "The repeat's modifier should carry a 'Bolt (repeat)' bucket")
	assert_eq(buckets.get(repeat_key, 0.0), SorcererTrait.REPEAT_FRACTION - 1.0)

func test_multiple_echo_charges_repeat_the_skill_multiple_times_with_compounding_damage() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var damage_results: Array[CombatResult] = _damage_results_against(results, 1)
	assert_eq(damage_results.size(), 3,
		"Two banked Echo charges should make the cast repeat twice, plus the original cast")
	assert_lt(damage_results[1].amount, damage_results[2].amount,
		"Each further Echo should compound and deal more than the previous Echo")

func test_echo_charges_clear_after_the_cast_that_consumes_them() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)

	resolver.ResolveSkill(0, [1], 0)

	assert_eq(caster_trait._echo_charges, 0, "Echo charges should be consumed by the cast that repeats")
	assert_eq(caster_trait._echoes_for_this_cast, 0, "The per-cast Echo counter should clear once spent")

func test_echo_on_a_zone_placing_cast_amplifies_the_zone_instead_of_repeating_damage() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	var caster: Character = resolver.GetCharacters()[0]
	caster._skills = [_make_zone_test_skill()]
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)

	resolver.ResolveSkill(0, [], 0)

	assert_almost_eq(resolver.GetZoneResolver().GetZones()[0]._damage_multiplier,
			SorcererTrait.ECHO_ZONE_AMPLIFICATION, 0.0001,
			"An Echo on a zone-placing cast should amplify the zone rather than repeat its damage")

func test_repeat_does_not_reapply_a_stackable_debuff() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var applied: Array[CombatResult] = results.filter(func(r: CombatResult) -> bool:
			return (CombatResult.Kind.Status_Applied == r.kind and not r.is_buff
					and Types.Debuff_Type.Burning == r.debuff_type))
	assert_eq(applied.size(), 1,
		"The repeat re-runs DamageEffects only; a stackable debuff must still be applied once")

func test_repeat_consumed_flag_does_not_carry_into_a_second_cast() -> void:
	var setup: Dictionary = _make_repeat_test_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait.OnReagentConsumed(0, ReagentData.new(), resolver)

	resolver.ResolveSkill(0, [1], 0)
	var second_results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	assert_eq(_damage_results_against(second_results, 1).size(), 1,
		"A second cast with no fresh reagent consumption must not repeat again")
