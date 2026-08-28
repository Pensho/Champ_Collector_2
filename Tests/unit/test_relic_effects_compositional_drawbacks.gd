extends GutTest

## The Relics whose drawback needs team reach: The Closed Wound, The Long Second, and The
## Unguarded Glass. (The Sealed Docket, the fourth of this batch, has its own test file —
## its Echo-strength drawback landed with the cascade-contributor plumbing.) Each Relic
## effect is exercised at two rarity steps, plus its drawback.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func _wearer_and_ally() -> Dictionary:
	var wearer: Character = TestFactory.make_character()
	wearer._current_health = wearer._attributes[Types.Attribute.Health]
	var ally: Character = TestFactory.make_character()
	ally._current_health = ally._attributes[Types.Attribute.Health]
	var resolver: BattleResolver = TestFactory.make_resolver(
			{0: wearer, 1: ally}, TestFactory.make_full_sides())
	return {"wearer": wearer, "ally": ally, "resolver": resolver}

# --- The Closed Wound ---

func test_closed_wound_grants_damage_bonus_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.25], [Types.Rarity.Legendary, 0.60]]:
		var relic: TheClosedWoundRelic = TheClosedWoundRelic.new()
		relic.Init(rarity_and_expected[0])

		assert_almost_eq(relic.GetOutgoingDamageBonus(0, 1, null), rarity_and_expected[1], 0.0001,
			"Rarity %s should grant its own ladder step, unconditionally" % Types.RarityName(rarity_and_expected[0]))

func test_closed_wound_blocks_healing_for_the_whole_team() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: TheClosedWoundRelic = TheClosedWoundRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic

	var ally_multiplier: float = Skills.TeamHealMultiplier(
			setup.resolver.GetSides(), setup.resolver.GetCharacters(), 1)
	var wearer_multiplier: float = Skills.TeamHealMultiplier(
			setup.resolver.GetSides(), setup.resolver.GetCharacters(), 0)

	assert_eq(ally_multiplier, 0.0, "A teammate's healing should be fully blocked")
	assert_eq(wearer_multiplier, 0.0, "The wearer's own healing is blocked too")

func test_closed_wound_does_not_block_an_enemys_healing() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: TheClosedWoundRelic = TheClosedWoundRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	var enemy: Character = TestFactory.make_character()
	setup.resolver.GetCharacters()[2] = enemy
	var sides: CombatSides = CombatSides.new([0, 1], [2])

	var enemy_multiplier: float = Skills.TeamHealMultiplier(sides, setup.resolver.GetCharacters(), 2)

	assert_eq(enemy_multiplier, 1.0, "An enemy's healing must be untouched by the wearer's drawback")

# --- The Long Second ---

func test_long_second_amplifies_a_forward_bump_granted_to_an_ally_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.20], [Types.Rarity.Legendary, 0.45]]:
		var setup: Dictionary = _wearer_and_ally()
		var relic: TheLongSecondRelic = TheLongSecondRelic.new()
		relic.Init(rarity_and_expected[0])
		setup.wearer._trait = relic

		var amplification: float = Skills.AllyTurnBarBumpAmplification(setup.wearer, 0)

		assert_almost_eq(amplification, rarity_and_expected[1], 0.0001,
			"Rarity %s should grant its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_long_second_reduces_a_teammates_applied_buff_magnitude() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: TheLongSecondRelic = TheLongSecondRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	var data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify)
	var base_value: float = setup.resolver.GetStatusResolver().SnapshotStatusValue(data, 1, 0)

	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	fortify.source_ID = 1
	setup.resolver.GetStatusResolver().ApplyBuff(0, fortify)

	var applied: StatusEffects.Buff = setup.wearer._active_buffs[0]
	assert_almost_eq(applied.value, base_value * 0.70, 0.01,
		"A buff an ally places on the wearer's team should be cut to 70%")

# --- The Unguarded Glass ---

func test_unguarded_glass_grants_crit_damage_while_holding_an_allys_buff_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.35], [Types.Rarity.Legendary, 0.80]]:
		var setup: Dictionary = _wearer_and_ally()
		var relic: TheUnguardedGlassRelic = TheUnguardedGlassRelic.new()
		relic.Init(rarity_and_expected[0])
		setup.wearer._trait = relic
		var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
		fortify.type = Types.Buff_Type.Fortify
		fortify.duration = 3
		fortify.source_ID = 1
		setup.resolver.GetStatusResolver().ApplyBuff(0, fortify)

		var delta: int = relic.GetAttributeDelta(Types.Attribute.CritDamage, 100)

		assert_eq(delta, int(ceilf(100 * rarity_and_expected[1])),
			"Rarity %s should grant its own ladder step while holding an ally's buff" % Types.RarityName(rarity_and_expected[0]))

func test_unguarded_glass_gives_no_bonus_for_a_self_granted_buff() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: TheUnguardedGlassRelic = TheUnguardedGlassRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	fortify.source_ID = 0
	setup.resolver.GetStatusResolver().ApplyBuff(0, fortify)

	assert_eq(relic.GetAttributeDelta(Types.Attribute.CritDamage, 100), 0,
		"A buff the wearer granted themself should not qualify")

func test_unguarded_glass_caps_the_wearer_at_one_buff() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: TheUnguardedGlassRelic = TheUnguardedGlassRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	fortify.source_ID = 1
	setup.resolver.GetStatusResolver().ApplyBuff(0, fortify)

	var haste: StatusEffects.Buff = StatusEffects.Buff.new()
	haste.type = Types.Buff_Type.Haste
	haste.duration = 3
	haste.source_ID = 1
	setup.resolver.GetStatusResolver().ApplyBuff(0, haste)

	assert_eq(setup.wearer._active_buffs.size(), 1, "A new buff must replace the one the wearer already holds")
	assert_eq(setup.wearer._active_buffs[0].type, Types.Buff_Type.Haste)
