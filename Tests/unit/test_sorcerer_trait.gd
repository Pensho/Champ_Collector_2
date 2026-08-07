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

# --- Rarity tables ---

func test_mysticism_per_stack_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.04,
		Types.Rarity.Rare: 0.06,
		Types.Rarity.Epic: 0.08,
		Types.Rarity.Legendary: 0.10,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(SorcererTrait.MYSTICISM_PER_STACK.get(rarity, 0.0), expected[rarity],
			"MYSTICISM_PER_STACK at %s" % Types.RarityName(rarity))

func test_reagent_amplification_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.20,
		Types.Rarity.Rare: 0.30,
		Types.Rarity.Epic: 0.40,
		Types.Rarity.Legendary: 0.50,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(SorcererTrait.REAGENT_AMPLIFICATION.get(rarity, 0.0), expected[rarity],
			"REAGENT_AMPLIFICATION at %s" % Types.RarityName(rarity))

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

func test_mysticism_bonus_scales_with_stacks_and_rarity() -> void:
	_InitTrait(Types.Rarity.Epic)  # 8% per stack
	var stack_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 0}
	_trait.OnSkillCast(0, [], "Zap", stack_attr, _resolver)
	_trait.OnSkillCast(0, [], "Zap", stack_attr, _resolver)
	assert_eq(_trait._instability_stacks, 2)

	var measure_attr: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], "Zap", measure_attr, _resolver)
	# 3 stacks x 8% of 100 = ceil(24) = 24
	assert_eq(measure_attr[Types.Attribute.Mysticism], 124,
		"Mysticism should be boosted by 3 stacks x 8% = 24")

# --- Reagent consumption hook ---

func test_reagent_consumption_grants_two_stacks() -> void:
	_InitTrait(Types.Rarity.Rare)
	_trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_eq(_trait._instability_stacks, 2, "Consuming a reagent should grant two stacks")

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

# --- Battle start ---

func test_stacks_reset_at_battle_start() -> void:
	_trait._instability_stacks = 3
	_trait.StartOfBattle(0, _resolver)
	assert_eq(_trait._instability_stacks, 0, "Instability stacks should not persist between combats")

# --- Reagent-triggered skill repeat ---

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
	assert_eq(buckets.get(repeat_key, 0.0), SorcererTrait.REPEAT_BONUS)

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
