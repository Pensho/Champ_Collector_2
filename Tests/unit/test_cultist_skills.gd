extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Regression coverage for the Cultist's Devotion bucket and Desecrated Blade's below-half-Health
# rider (Role_Kit_Design.md section 9.8) — the load-bearing claim being that Devotion and the
# per-cast trait_resource bonus land in two distinct CombinedDamageModifier buckets and
# therefore multiply rather than add.

## The Chosen Vessel drain (SetCurrentHealth) also emits a Damage-kind CombatResult with no
## combined_damage_modifier, so this skips past it to the actual skill damage.
func _damage_modifier(p_results: Array[CombatResult]) -> CombinedDamageModifier:
	for r in p_results:
		if(r.kind == CombatResult.Kind.Damage and null != r.combined_damage_modifier):
			return r.combined_damage_modifier
	return null

func _desecrated_blade_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Desecrated Blade"
	skill.target = Types.Skill_Target.Single_Enemy
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 0.9}
	effect.bonus_per = {Types.Trait_Count_Source.Trait_Condition: 0.25}
	skill.effects = [effect]
	return skill

func _setup() -> Dictionary:
	var roster: Dictionary[int, Character] = {}
	roster.assign(TestFactory.make_full_roster())
	var cultist_trait: ChosenVesselTrait = ChosenVesselTrait.new()
	cultist_trait.Init(Types.Rarity.Legendary)
	roster[0]._trait = cultist_trait
	roster[0]._skills = [_desecrated_blade_skill(), TestFactory.make_strike_skill()]
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	cultist_trait.StartOfBattle(0, resolver)
	return {"roster": roster, "resolver": resolver, "trait": cultist_trait}

func test_desecrated_blade_has_no_rider_with_a_full_health_vessel() -> void:
	var setup: Dictionary = _setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var cultist_trait: ChosenVesselTrait = setup["trait"]
	var vessel_ID: int = cultist_trait._vessel_ID
	roster[vessel_ID]._current_health = resolver.GetMaxHealth(vessel_ID)

	var modifier: CombinedDamageModifier = _damage_modifier(resolver.ResolveSkill(0, [3], 0))

	assert_eq(modifier.Buckets().get(&"Desecrated Blade", 0.0), 0.0,
		"A full-Health Vessel should not trigger Desecrated Blade's rider")

func test_desecrated_blade_gains_the_rider_with_a_sub_half_health_vessel() -> void:
	var setup: Dictionary = _setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var cultist_trait: ChosenVesselTrait = setup["trait"]
	var vessel_ID: int = cultist_trait._vessel_ID
	var max_health: int = resolver.GetMaxHealth(vessel_ID)
	roster[vessel_ID]._current_health = int(max_health * 0.4)

	var modifier: CombinedDamageModifier = _damage_modifier(resolver.ResolveSkill(0, [3], 0))

	assert_almost_eq(modifier.Buckets()[&"Desecrated Blade"], 0.25, 0.0001,
		"A sub-half-Health Vessel should trigger Desecrated Blade's +25% rider")

func test_devotion_and_the_per_cast_bonus_land_in_distinct_buckets_and_multiply() -> void:
	var setup: Dictionary = _setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var cultist_trait: ChosenVesselTrait = setup["trait"]
	var first_vessel_ID: int = cultist_trait._vessel_ID
	resolver.SetCurrentHealth(first_vessel_ID, 0)
	assert_eq(cultist_trait._devotion_count, 1, "The Vessel's death should have credited Devotion")

	var non_basic: Skill = TestFactory.make_strike_skill()
	non_basic.name = "Devour Blessing"
	non_basic.cooldown = 3
	roster[0]._skills.append(non_basic)

	var modifier: CombinedDamageModifier = _damage_modifier(resolver.ResolveSkill(0, [3], 2))

	assert_almost_eq(modifier.Buckets()[&"trait_damage_bonus"], 0.20, 0.0001,
		"Devotion should land in its own bucket, independent of the per-cast bonus")
	assert_almost_eq(modifier.Buckets()[CombinedDamageModifier.TRAIT_RESOURCE_KEY], 0.30, 0.0001,
		"The per-cast bonus should still land in the shared trait_resource bucket")
	assert_almost_eq(modifier.Product(), 1.30 * 1.20, 0.0001,
		"Two distinct buckets must multiply rather than add")
