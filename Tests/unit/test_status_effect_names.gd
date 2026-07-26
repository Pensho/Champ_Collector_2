extends GutTest

func test_buff_name_replaces_underscores_with_spaces() -> void:
	assert_eq(Types.BuffName(Types.Buff_Type.Daunting_Strength), "Daunting Strength")

func test_buff_name_single_word() -> void:
	assert_eq(Types.BuffName(Types.Buff_Type.Empower), "Empower")

func test_debuff_name_replaces_underscores_with_spaces() -> void:
	assert_eq(Types.DebuffName(Types.Debuff_Type.Expose_Weakness), "Expose Weakness")

func test_debuff_name_single_word() -> void:
	assert_eq(Types.DebuffName(Types.Debuff_Type.Burning), "Burning")
