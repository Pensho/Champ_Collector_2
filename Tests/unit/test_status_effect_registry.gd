extends GutTest

# Data-integrity net for the status-effect registry (Plan_Data_Driven_Status_Effects):
# every implemented Buff_Type/Debuff_Type value must resolve to a StatusEffectData
# resource, mirroring test_character_preset_skill_invariant.gd's per-enum-value check.

func test_every_implemented_buff_type_has_registry_data() -> void:
	for buff_name in Types.Buff_Type.keys():
		var buff_type: Types.Buff_Type = Types.Buff_Type[buff_name]
		if(Types.Buff_Type.Invalid == buff_type):
			continue
		assert_not_null(StatusEffectRegistry.BuffData(buff_type),
			"Buff_Type.%s has no StatusEffectData registered" % buff_name)

func test_every_implemented_debuff_type_has_registry_data() -> void:
	for debuff_name in Types.Debuff_Type.keys():
		var debuff_type: Types.Debuff_Type = Types.Debuff_Type[debuff_name]
		if(Types.Debuff_Type.Invalid == debuff_type):
			continue
		assert_not_null(StatusEffectRegistry.DebuffData(debuff_type),
			"Debuff_Type.%s has no StatusEffectData registered" % debuff_name)

func test_burning_is_stackable_and_not_overwritable() -> void:
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Burning)
	assert_true(data.stackable, "Burning must stack (Lava-zone repeated triggers)")
	assert_false(data.overwritable, "Burning instances must not overwrite each other's duration")

func test_non_burning_debuffs_are_overwritable_not_stackable() -> void:
	for debuff_type in [Types.Debuff_Type.Enfeeble, Types.Debuff_Type.Expose_Weakness]:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff_type)
		assert_true(data.overwritable)
		assert_false(data.stackable)
