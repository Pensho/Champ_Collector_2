extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# StatusEffectData.caster_scaled: an instance's value is snapshotted off the applier's own
# attributes at application time, independent of magnitude_kind.

func test_caster_scaled_debuff_snapshots_off_the_appliers_attribute() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.Knowledge] = 200
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Cracked_Facet
	template.duration = 3
	template.source_ID = 0
	resolver.GetStatusResolver().ApplyDebuff(3, template)

	assert_almost_eq(roster[3]._active_debuffs[0].value, 120.0, 0.0001,
		"Cracked Facet must snapshot 60% of the applier's own Knowledge (200), not a flat magnitude")

func test_caster_scaled_buff_snapshots_through_apply_buff() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.CritChance] = 60
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Keen_Edge
	template.duration = 3
	template.source_ID = 0
	resolver.GetStatusResolver().ApplyBuff(1, template)

	assert_almost_eq(roster[1]._active_buffs[0].value, 60.0, 0.0001,
		"Keen Edge must snapshot the applier's own Critical Chance (60) through ApplyBuff, which " +
		"previously never snapshotted a value at all")

func test_caster_scaled_snapshot_ignores_the_targets_own_attributes() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.CritDamage] = 250
	roster[1]._attributes[Types.Attribute.CritDamage] = 999
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Lethal_Precision
	template.duration = 3
	template.source_ID = 0
	resolver.GetStatusResolver().ApplyBuff(1, template)

	assert_almost_eq(roster[1]._active_buffs[0].value, 250.0, 0.0001,
		"The snapshot must read the applier's Critical Damage, not the target's own")
